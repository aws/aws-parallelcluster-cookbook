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

"""Unit tests for the installed-version probes of the critical third-party software."""

import pytest

from pcluster_diag.util import software_versions
from tests.test_helpers import completed_process, raise_oserror


def _fake_run_command(outputs):
    """Return a run_command double answering each command (by its first argument) with ``outputs``."""
    calls = []

    def fake(command, *_args, **_kwargs):
        calls.append(command)
        returncode, stdout = outputs.get(command[0], (127, ""))
        return completed_process(returncode, stdout=stdout)

    fake.calls = calls
    return fake


def test_slurm_version_parses_sinfo(monkeypatch):
    fake = _fake_run_command({"/opt/slurm/bin/sinfo": (0, "slurm 25.11.8\n")})
    monkeypatch.setattr(software_versions, "run_command", fake)

    assert software_versions.slurm_version("/opt/slurm/") == "25.11.8"
    assert fake.calls == [["/opt/slurm/bin/sinfo", "--version"]]


@pytest.mark.parametrize("returncode, stdout", [(1, ""), (0, "unexpected output")])
def test_slurm_version_none_when_unreadable(monkeypatch, returncode, stdout):
    monkeypatch.setattr(
        software_versions, "run_command", _fake_run_command({"/opt/slurm/bin/sinfo": (returncode, stdout)})
    )

    assert software_versions.slurm_version("/opt/slurm") is None


def test_slurm_version_none_when_binary_missing(monkeypatch):
    monkeypatch.setattr(software_versions, "run_command", raise_oserror)

    assert software_versions.slurm_version("/opt/slurm") is None


def test_efa_installer_version_reads_installed_packages_file(monkeypatch, tmp_path):
    path = tmp_path / "efa_installed_packages"
    path.write_text("# EFA installer version: 1.49.0\n# Debug packages installed: no\nefa-2.17.0-1\n", encoding="utf-8")
    monkeypatch.setattr(software_versions, "EFA_INSTALLED_PACKAGES_PATH", str(path))

    assert software_versions.efa_installer_version() == "1.49.0"


def test_efa_installer_version_none_when_file_missing_or_unparseable(monkeypatch, tmp_path):
    monkeypatch.setattr(software_versions, "EFA_INSTALLED_PACKAGES_PATH", str(tmp_path / "missing"))
    assert software_versions.efa_installer_version() is None

    path = tmp_path / "efa_installed_packages"
    path.write_text("efa-2.17.0-1\n", encoding="utf-8")
    monkeypatch.setattr(software_versions, "EFA_INSTALLED_PACKAGES_PATH", str(path))
    assert software_versions.efa_installer_version() is None


def test_kernel_module_probes_read_modinfo(monkeypatch):
    modules = []

    def fake_module_version(module):
        modules.append(module)
        return {"nvidia": "595.71.05", "gdrdrv": "2.6"}.get(module)

    monkeypatch.setattr(software_versions.kernel_module, "module_version", fake_module_version)

    assert software_versions.nvidia_driver_version() == "595.71.05"
    assert software_versions.gdrcopy_version() == "2.6"
    assert modules == ["nvidia", "gdrdrv"]


def test_cuda_version_runs_nvcc_of_the_expected_release(monkeypatch):
    nvcc = "/usr/local/cuda-13.2/bin/nvcc"
    fake = _fake_run_command(
        {nvcc: (0, "nvcc: NVIDIA (R) Cuda compiler driver\nCuda compilation tools, release 13.2, V13.2.78\n")}
    )
    monkeypatch.setattr(software_versions, "run_command", fake)

    assert software_versions.cuda_version("13.2.2") == "13.2"
    assert fake.calls == [[nvcc, "--version"]]


def test_cuda_version_none_when_not_installed(monkeypatch):
    monkeypatch.setattr(software_versions, "run_command", raise_oserror)

    assert software_versions.cuda_version("13.2.2") is None


def _pci_device(root, name, vendor, device_id="0x0000", pci_class="0x000000"):
    device = root / name
    device.mkdir()
    (device / "vendor").write_text(vendor + "\n", encoding="utf-8")
    (device / "device").write_text(device_id + "\n", encoding="utf-8")
    (device / "class").write_text(pci_class + "\n", encoding="utf-8")


@pytest.mark.parametrize(
    "vendors, expected", [(["0x1d0f", "0x10DE"], True), (["0x1d0f", "0x8086"], False), ([], False)]
)
def test_has_nvidia_gpu_reads_pci_vendors(monkeypatch, tmp_path, vendors, expected):
    for index, vendor in enumerate(vendors):
        _pci_device(tmp_path, "0000:00:0{}.0".format(index), vendor)
    (tmp_path / "0000:00:1f.0").mkdir()  # a device without a readable vendor is ignored
    monkeypatch.setattr(software_versions, "PCI_DEVICES_SYSFS", str(tmp_path))

    assert software_versions.has_nvidia_gpu() is expected


def test_has_nvidia_gpu_false_when_sysfs_missing(monkeypatch, tmp_path):
    monkeypatch.setattr(software_versions, "PCI_DEVICES_SYSFS", str(tmp_path / "missing"))

    assert software_versions.has_nvidia_gpu() is False


@pytest.mark.parametrize(
    "version, count, expected",
    [
        ("25-11-8-1", 3, ["25", "11", "8"]),
        ("13.2.2", 2, ["13", "2"]),
        ("2.6", 3, ["2", "6"]),
        (" 1.49.0 ", 3, ["1", "49", "0"]),
    ],
)
def test_version_parts(version, count, expected):
    assert software_versions.version_parts(version, count) == expected


@pytest.mark.parametrize(
    "installed, expected, count, match",
    [
        ("25.11.8", "25-11-8-1", 3, True),
        ("25.11.6", "25-11-8-1", 3, False),
        ("595.71.5", "595.71.05", 3, True),
        ("13.2", "13.2.2", 2, True),
        ("13.1", "13.2.2", 2, False),
        ("2.6", "2.6", 2, True),
        ("1.49.0", "1.49.0", 3, True),
        ("1.49.0rc1", "1.49.0", 3, False),
    ],
)
def test_versions_match(installed, expected, count, match):
    assert software_versions.versions_match(installed, expected, count) is match


def test_fabric_manager_version_parses_nv_fabricmanager(monkeypatch):
    fake = _fake_run_command({"/usr/bin/nv-fabricmanager": (0, "Fabric Manager version is : 595.71.05\n")})
    monkeypatch.setattr(software_versions, "run_command", fake)

    assert software_versions.fabric_manager_version() == "595.71.05"
    assert fake.calls == [["/usr/bin/nv-fabricmanager", "--version"]]


def test_fabric_manager_version_none_when_not_installed(monkeypatch):
    monkeypatch.setattr(software_versions, "run_command", raise_oserror)

    assert software_versions.fabric_manager_version() is None


_GPU = ("0x10de", "0x2330", "0x030200")
_NVSWITCH = ("0x10de", "0x22a3", "0x068000")
_INFINIBAND = ("0x15b3", "0x1021", "0x020700")
_GB200 = ("0x10de", "0x2941", "0x030200")


@pytest.mark.parametrize(
    "devices, expected",
    [
        pytest.param([_GPU] * 8 + [_NVSWITCH] * 4, True, id="p5: GPUs and NVSwitches"),
        pytest.param([_GPU] * 8 + [_INFINIBAND] * 8, True, id="p6-b300: GPUs and InfiniBand controllers"),
        pytest.param([_GB200] * 4 + [_NVSWITCH] * 2, False, id="GB200"),
        pytest.param([_GPU] * 8, False, id="no NVSwitch"),
        pytest.param([_GPU] + [_NVSWITCH] * 4, False, id="single GPU"),
        pytest.param([], False, id="no device"),
    ],
)
def test_fabric_manager_expected(monkeypatch, tmp_path, devices, expected):
    for index, (vendor, device_id, pci_class) in enumerate(devices):
        _pci_device(tmp_path, "0000:00:{:02x}.0".format(index), vendor, device_id, pci_class)
    monkeypatch.setattr(software_versions, "PCI_DEVICES_SYSFS", str(tmp_path))

    assert software_versions.fabric_manager_expected() is expected


def test_kernels_with_module(monkeypatch, tmp_path):
    for kernel, module_path in [
        ("6.1.155-176.282.amzn2023.x86_64", "extra/nvidia.ko.xz"),
        ("6.1.155-176.282.amzn2023.x86_64", "kernel/drivers/infiniband/hw/efa/efa.ko.xz"),
        ("6.1.200-1.amzn2023.x86_64", "kernel/drivers/infiniband/hw/efa/efa.ko.xz"),
        ("5.10.0-1.amzn2.x86_64", "updates/dkms/nvidia.ko"),
    ]:
        path = tmp_path / kernel / module_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("", encoding="utf-8")
    (tmp_path / "6.1.200-1.amzn2023.x86_64" / "extra").mkdir()
    (tmp_path / "6.1.200-1.amzn2023.x86_64" / "extra" / "nvidia-uvm.ko").write_text("", encoding="utf-8")
    monkeypatch.setattr(software_versions, "LIB_MODULES_PATH", str(tmp_path))

    assert software_versions.kernels_with_module("nvidia") == [
        "5.10.0-1.amzn2.x86_64",
        "6.1.155-176.282.amzn2023.x86_64",
    ]
    assert software_versions.kernels_with_module("efa") == [
        "6.1.155-176.282.amzn2023.x86_64",
        "6.1.200-1.amzn2023.x86_64",
    ]
    assert software_versions.kernels_with_module("gdrdrv") == []
