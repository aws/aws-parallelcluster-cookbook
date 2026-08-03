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

"""Unit tests for the shared-storage enumeration and /proc/mounts helpers."""

import pytest

from pcluster_diag.models.context import NodeType
from pcluster_diag.util import shared_storage
from tests.sample_data import sample_context, sample_context_with_lustre
from tests.test_helpers import completed_process as _completed
from tests.test_helpers import raise_oserror as _raise_oserror

_PROC_MOUNTS = """\
proc /proc proc rw,relatime 0 0
10.0.0.1@tcp:/fsname /fsx lustre rw,relatime 0 0
10.0.0.2@tcp:/efaname /fsx-efa lustre rw,relatime 0 0
/dev/nvme0n1 / ext4 rw 0 0
"""


# --- SharedStorage enumeration --------------------------------------------------------


def test_shared_storage_mounts_empty_when_no_shared_storage():
    assert shared_storage.shared_storage_mounts(sample_context(NodeType.HEAD)) == []


def test_lustre_mounts_returns_both_fsx_lustre_mounts():
    mounts = shared_storage.lustre_mounts(sample_context_with_lustre(NodeType.HEAD))

    assert [m.mount_dir for m in mounts] == ["/fsx", "/fsx-efa"]
    assert mounts[0].storage_type == "FsxLustre"
    assert mounts[0].file_system_id == "fs-0123456789abcdef0"
    assert mounts[0].name == "fsx"


def test_lustre_mounts_filters_out_non_lustre_types():
    storage = [
        {"Name": "fsx", "StorageType": "FsxLustre", "MountDir": "/fsx"},
        {"Name": "efs", "StorageType": "Efs", "MountDir": "/efs"},
        {"Name": "ebs", "StorageType": "Ebs", "MountDir": "/ebs"},
    ]
    context = sample_context_with_lustre(NodeType.HEAD, shared_storage=storage)

    mounts = shared_storage.lustre_mounts(context)

    assert [m.mount_dir for m in mounts] == ["/fsx"]


def test_shared_storage_mounts_normalizes_relative_mount_dir():
    # ParallelCluster accepts a relative MountDir (e.g. "fsx") and mounts it at "/fsx"; the mounts we
    # return must be absolute so they match /proc/mounts and the path passed to `lfs df`.
    storage = [
        {"Name": "fsx", "StorageType": "FsxLustre", "MountDir": "fsx"},
        {"Name": "efs", "StorageType": "Efs", "MountDir": "shared/efs"},
        {"Name": "abs", "StorageType": "FsxLustre", "MountDir": "/already/abs"},
    ]
    context = sample_context_with_lustre(NodeType.HEAD, shared_storage=storage)

    mounts = shared_storage.shared_storage_mounts(context)

    assert [m.mount_dir for m in mounts] == ["/fsx", "/shared/efs", "/already/abs"]


def test_shared_storage_mounts_skips_malformed_entries():
    storage = [
        {"StorageType": "FsxLustre"},  # no MountDir
        {"MountDir": "/x"},  # no StorageType
        "not-a-dict",
        {"Name": "ok", "StorageType": "FsxLustre", "MountDir": "/fsx"},
    ]
    context = sample_context_with_lustre(NodeType.HEAD, shared_storage=storage)

    mounts = shared_storage.shared_storage_mounts(context)

    assert [m.mount_dir for m in mounts] == ["/fsx"]


# --- /proc/mounts parsing -------------------------------------------------------------


def test_parse_proc_mounts_parses_entries_and_skips_short_lines():
    mounts = shared_storage.parse_proc_mounts(_PROC_MOUNTS + "bad line\n")

    lustre_entries = [m for m in mounts if m.fs_type == "lustre"]
    assert [m.mount_point for m in lustre_entries] == ["/fsx", "/fsx-efa"]


@pytest.mark.parametrize(
    "mount_dir, fs_type, expected",
    [
        ("/fsx", "lustre", True),
        ("/fsx-efa", "lustre", True),
        ("/fsx", "nfs", False),  # right dir, wrong type
        ("/missing", "lustre", False),
    ],
)
def test_is_mounted(mount_dir, fs_type, expected):
    mounts = shared_storage.parse_proc_mounts(_PROC_MOUNTS)

    assert shared_storage.is_mounted(mounts, mount_dir, fs_type) is expected


def test_read_mounts_parses_cat_output(monkeypatch):
    monkeypatch.setattr(shared_storage, "run_command", lambda command: _completed(stdout=_PROC_MOUNTS))

    mounts = shared_storage.read_mounts()

    assert shared_storage.is_mounted(mounts, "/fsx", "lustre") is True


def test_read_mounts_returns_empty_on_nonzero_exit(monkeypatch):
    monkeypatch.setattr(shared_storage, "run_command", lambda command: _completed(returncode=1))

    assert shared_storage.read_mounts() == []


def test_read_mounts_returns_empty_when_cat_missing(monkeypatch):
    monkeypatch.setattr(shared_storage, "run_command", _raise_oserror)

    assert shared_storage.read_mounts() == []
