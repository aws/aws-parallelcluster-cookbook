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

"""Unit tests for the FSx for Lustre client, mount-presence, and reachability checks."""

import pytest

from pcluster_diag.checks import fsx_connectivity
from pcluster_diag.checks.fsx_connectivity import (
    FsxFilesystemsAreReachable,
    FsxMountsArePresent,
    LustreClientIsInstalled,
)
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.util.shell import TimedCommand
from tests.sample_data import sample_context, sample_context_with_lustre

_HEALTHY_LFS_DF = """\
UUID                       bytes        Used   Available Use% Mounted on
fs-abc-MDT0000_UUID         2.0G       10.0M        1.9G   1% /fsx[MDT:0]
fs-abc-OST0000_UUID        10.0T        1.0T        9.0T  10% /fsx[OST:0]

filesystem_summary:        12.0T        1.0T       11.0T   9% /fsx
"""

_DEGRADED_LFS_DF = """\
UUID                       bytes        Used   Available Use% Mounted on
fs-abc-MDT0000_UUID         2.0G       10.0M        1.9G   1% /fsx[MDT:0]
fs-abc-OST0001_UUID : Resource temporarily unavailable
"""

_PROC_MOUNTS_BOTH = """\
10.0.0.1@tcp:/a /fsx lustre rw 0 0
10.0.0.2@tcp:/b /fsx-efa lustre rw 0 0
"""

_PROC_MOUNTS_ONLY_FSX = "10.0.0.1@tcp:/a /fsx lustre rw 0 0\n"


def _timed(returncode=0, stdout="", stderr="", timed_out=False, elapsed=0.01):
    return TimedCommand(
        command=["lfs", "df", "-h"],
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
        elapsed_seconds=elapsed,
        timed_out=timed_out,
    )


def _codes(result):
    return [finding.code for finding in (result.errors or [])]


def _warn_codes(result):
    return [finding.code for finding in (result.warnings or [])]


def _info_codes(result):
    return [finding.code for finding in (result.infos or [])]


def _messages(result):
    return " | ".join(finding.message for finding in (result.errors or []))


# --- should_run gating (shared by all three checks) -----------------------------------


@pytest.mark.parametrize("check", [LustreClientIsInstalled(), FsxMountsArePresent(), FsxFilesystemsAreReachable()])
@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_should_run_true_on_all_node_types_when_lustre_configured(check, node_type):
    assert check.should_run(sample_context_with_lustre(node_type)) is True


@pytest.mark.parametrize("check", [LustreClientIsInstalled(), FsxMountsArePresent(), FsxFilesystemsAreReachable()])
def test_should_run_false_when_no_lustre_configured(check):
    assert check.should_run(sample_context(NodeType.HEAD)) is False


# --- LustreClientIsInstalled ----------------------------------------------------------


def _patch_client(monkeypatch, *, installed=True, available=True, loaded=True, version="2.15.6"):
    monkeypatch.setattr(fsx_connectivity.lustre, "lustre_client_installed", lambda packages: installed)
    monkeypatch.setattr(fsx_connectivity.packages, "kernel_module_available", lambda module: available)
    monkeypatch.setattr(fsx_connectivity.packages, "kernel_module_loaded", lambda module: loaded)
    monkeypatch.setattr(fsx_connectivity.packages, "kernel_release", lambda: "6.1.0-amzn2023")
    monkeypatch.setattr(fsx_connectivity.lustre, "lustre_client_version", lambda: version)


def test_client_description():
    assert "Lustre client" in LustreClientIsInstalled().description


def test_client_all_present_passes_with_version_info(monkeypatch):
    _patch_client(monkeypatch)

    result = LustreClientIsInstalled().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.PASSED
    assert _info_codes(result) == [LustreClientIsInstalled.CLIENT_VERSION.code]
    assert "2.15.6" in result.infos[0].message


def test_client_package_missing_fails(monkeypatch):
    _patch_client(monkeypatch, installed=False)

    result = LustreClientIsInstalled().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert LustreClientIsInstalled.PACKAGE_MISSING.code in _codes(result)


def test_client_module_unavailable_fails_naming_kernel(monkeypatch):
    _patch_client(monkeypatch, available=False)

    result = LustreClientIsInstalled().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert LustreClientIsInstalled.MODULE_UNAVAILABLE.code in _codes(result)
    assert "6.1.0-amzn2023" in _messages(result)


def test_client_modules_not_loaded_is_warning_only(monkeypatch):
    _patch_client(monkeypatch, loaded=False)

    result = LustreClientIsInstalled().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.WARNING
    assert _warn_codes(result) == [LustreClientIsInstalled.MODULES_NOT_LOADED.code]


# --- FsxMountsArePresent --------------------------------------------------------------


def test_mounts_description():
    assert "mounted" in FsxMountsArePresent().description


def test_mounts_all_present_passes(monkeypatch):
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_BOTH))

    result = FsxMountsArePresent().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.PASSED


def test_mounts_missing_one_fails_naming_only_that_mount(monkeypatch):
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_ONLY_FSX))

    result = FsxMountsArePresent().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [FsxMountsArePresent.NOT_MOUNTED.code]
    assert "/fsx-efa" in _messages(result)
    assert "'/fsx'" not in _messages(result)


def test_mounts_none_present_fails_for_all(monkeypatch):
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(""))

    result = FsxMountsArePresent().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [FsxMountsArePresent.NOT_MOUNTED.code, FsxMountsArePresent.NOT_MOUNTED.code]


def _mounts_from(proc_mounts):
    from pcluster_diag.util.shared_storage import parse_proc_mounts

    parsed = parse_proc_mounts(proc_mounts)
    return lambda: parsed


# --- FsxFilesystemsAreReachable -------------------------------------------------------


def _patch_lfs(monkeypatch, results_by_mount):
    """Patch time_command to return a per-mount TimedCommand keyed by the mount dir argument."""

    def fake_time_command(command, timeout):
        mount_dir = command[-1]
        return results_by_mount[mount_dir]

    monkeypatch.setattr(fsx_connectivity, "time_command", fake_time_command)


def test_reachable_description():
    assert "reachable" in FsxFilesystemsAreReachable().description


def test_reachable_all_healthy_passes(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {"/fsx": _timed(stdout=_HEALTHY_LFS_DF), "/fsx-efa": _timed(stdout=_HEALTHY_LFS_DF)},
    )

    result = FsxFilesystemsAreReachable().run(sample_context_with_lustre(NodeType.LOGIN))

    assert result.status is Status.PASSED


def test_reachable_hang_reports_timeout_for_only_that_mount(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {
            "/fsx": _timed(stdout=_HEALTHY_LFS_DF),
            "/fsx-efa": _timed(returncode=None, timed_out=True, elapsed=30.0),
        },
    )

    result = FsxFilesystemsAreReachable().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert _codes(result) == [FsxFilesystemsAreReachable.LFS_DF_TIMED_OUT.code]
    assert "/fsx-efa" in _messages(result)
    assert "hanging" in _messages(result)


def test_reachable_nonzero_exit_reports_error(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {
            "/fsx": _timed(returncode=1, stderr="cannot send after transport endpoint shutdown"),
            "/fsx-efa": _timed(stdout=_HEALTHY_LFS_DF),
        },
    )

    result = FsxFilesystemsAreReachable().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [FsxFilesystemsAreReachable.LFS_DF_FAILED.code]
    assert "transport endpoint shutdown" in _messages(result)


def test_reachable_down_target_reports_target_unavailable(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {"/fsx": _timed(stdout=_DEGRADED_LFS_DF), "/fsx-efa": _timed(stdout=_HEALTHY_LFS_DF)},
    )

    result = FsxFilesystemsAreReachable().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [FsxFilesystemsAreReachable.TARGET_UNAVAILABLE.code]
    assert "fs-abc-OST0001_UUID" in _messages(result)
    assert "/fsx" in _messages(result)


def test_reachable_aggregates_multiple_mount_failures(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {
            "/fsx": _timed(returncode=None, timed_out=True, elapsed=30.0),
            "/fsx-efa": _timed(returncode=2, stderr="No such device"),
        },
    )

    result = FsxFilesystemsAreReachable().run(sample_context_with_lustre(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [
        FsxFilesystemsAreReachable.LFS_DF_TIMED_OUT.code,
        FsxFilesystemsAreReachable.LFS_DF_FAILED.code,
    ]
