# Copyright 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

"""Unit tests for the EFA capability helpers (kefalnd/driver modules, versions, device count, p6+)."""

import pytest

from pcluster_diag.util import efa


def test_efa_kefalnd_supported_delegates_to_modinfo(monkeypatch):
    monkeypatch.setattr(efa.kernel_module, "kernel_module_available", lambda module: module == "kefalnd")
    assert efa.efa_kefalnd_supported() is True
    monkeypatch.setattr(efa.kernel_module, "kernel_module_available", lambda module: False)
    assert efa.efa_kefalnd_supported() is False


def test_efa_driver_version_delegates_to_modinfo(monkeypatch):
    monkeypatch.setattr(efa.kernel_module, "module_version", lambda module: "2.12.1" if module == "efa" else None)
    assert efa.efa_driver_version() == "2.12.1"


def test_efa_kefalnd_version_delegates_to_modinfo(monkeypatch):
    monkeypatch.setattr(efa.kernel_module, "module_version", lambda module: "1.1.1" if module == "kefalnd" else None)
    assert efa.efa_kefalnd_version() == "1.1.1"


def _patch_infiniband(monkeypatch, drivers):
    """Simulate /sys/class/infiniband: ``drivers`` maps each device name to its resolved driver name.

    ``os.listdir`` returns the device names; ``os.path.realpath`` on ``<dev>/device/driver`` resolves to a
    path whose basename is the mapped driver (so efa_device_count's driver filter can be exercised).
    """
    monkeypatch.setattr(efa.os, "listdir", lambda path: list(drivers))
    monkeypatch.setattr(efa.os.path, "realpath", lambda link: "/sys/bus/pci/drivers/" + drivers[link.split("/")[-3]])


def test_efa_device_count_counts_only_efa_driver_devices(monkeypatch):
    # Two efa devices and one non-EFA RDMA device (e.g. an ib device) under /sys/class/infiniband.
    _patch_infiniband(monkeypatch, {"efa0": "efa", "efa1": "efa", "mlx5_0": "mlx5_core"})
    assert efa.efa_device_count() == 2


def test_efa_device_count_zero_when_no_efa_devices(monkeypatch):
    _patch_infiniband(monkeypatch, {"mlx5_0": "mlx5_core"})
    assert efa.efa_device_count() == 0


def test_efa_device_count_zero_when_sysfs_absent(monkeypatch):
    def _raise(path):
        raise OSError("no such directory")

    monkeypatch.setattr(efa.os, "listdir", _raise)
    assert efa.efa_device_count() == 0


def test_efa_device_count_skips_device_whose_driver_is_unreadable(monkeypatch):
    monkeypatch.setattr(efa.os, "listdir", lambda path: ["efa0", "broken"])

    def _realpath(link):
        if "broken" in link:
            raise OSError("dangling symlink")
        return "/sys/bus/pci/drivers/efa"

    monkeypatch.setattr(efa.os.path, "realpath", _realpath)
    assert efa.efa_device_count() == 1


@pytest.mark.parametrize(
    "instance_type, expected",
    [
        ("p6-b300.48xlarge", True),
        ("p6-b200.48xlarge", True),
        ("p6e-gb200.36xlarge", True),
        ("p5.48xlarge", False),
        ("c5n.18xlarge", False),
        # An unknown instance type (e.g. IMDS unavailable at startup) is undeterminable, not "non-p6".
        ("", None),
        (None, None),
    ],
)
def test_is_p6plus_instance(instance_type, expected):
    assert efa.is_p6plus_instance(instance_type) is expected


@pytest.mark.parametrize(
    "instance_type, available, expected",
    [
        # Fixed per-instance-type counts from the FSx-for-Lustre configure-efa-clients doc table.
        ("p6-b300.48xlarge", 16, 16),
        ("p6-b200.48xlarge", 8, 8),
        ("p6e-gb200.36xlarge", 8, 8),
        ("p5.48xlarge", 16, 8),
        ("p5en.48xlarge", 16, 8),
        # Expected count is capped at devices actually present.
        ("p5.48xlarge", 4, 4),
        ("p6-b300.48xlarge", 8, 8),
        # Instance types not in the table bind ALL present devices: the expectation is derived from the
        # node, not from the doc's stale "other instances with multiple network cards -> 2" row.
        ("trn1.32xlarge", 8, 8),
        ("c5n.18xlarge", 2, 2),
        ("c5n.18xlarge", 1, 1),
        # An unknown instance type (IMDS unreachable) yields no expectation at all.
        (None, 16, None),
    ],
)
def test_expected_bound_device_count(instance_type, available, expected):
    assert efa.expected_bound_device_count(instance_type, available) == expected
