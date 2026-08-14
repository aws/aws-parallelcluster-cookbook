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

"""Unit tests for the consolidated LustreFilesystem check and the opt-in FsxTargetsAreReachable check.

Each probe of the consolidated ``LustreFilesystem`` check is exercised directly (``_probe_*`` with its own
finding lists), plus a few ``run``-level tests covering aggregation and probe-crash isolation.
"""

import pytest

from pcluster_diag.checks import fsx_connectivity
from pcluster_diag.checks.fsx_connectivity import FsxTargetsAreReachable, LustreFilesystem, _LnetSnapshot
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.util.shell import TimedCommand
from tests.sample_data import sample_context, sample_context_with_lustre
from tests.test_helpers import DEGRADED_LFS_DF as _DEGRADED_LFS_DF
from tests.test_helpers import HEALTHY_LFS_DF as _HEALTHY_LFS_DF

_PROC_MOUNTS_BOTH = """\
10.0.0.1@tcp:/a /fsx lustre rw 0 0
10.0.0.2@tcp:/b /fsx-efa lustre rw 0 0
"""

_PROC_MOUNTS_ONLY_FSX = "10.0.0.1@tcp:/a /fsx lustre rw 0 0\n"

# Placeholder instance types for the family-gate tests. The p6+ one only needs to start with a known p6+
# family prefix (the gate matches on prefix), and the non-p6 one only needs to not; neither is a real size.
_FAKE_P6PLUS_INSTANCE_TYPE = "p6-b200.fake"
_FAKE_NON_P6_INSTANCE_TYPE = "fake.large"


def _timed(returncode=0, stdout="", stderr="", timed_out=False, elapsed=0.01):
    return TimedCommand(
        command=["lfs", "df", "-h"],
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
        elapsed_seconds=elapsed,
        timed_out=timed_out,
    )


def _codes(findings):
    return [finding.code for finding in (findings or [])]


def _messages(findings):
    return " | ".join(finding.message for finding in (findings or []))


def _info_codes(result):
    return [finding.code for finding in (result.infos or [])]


def _snapshot(stdout):
    """Build an _LnetSnapshot from parsed ``lnetctl net show -v`` output (as the check would fetch it)."""
    from pcluster_diag.util import lustre

    return _LnetSnapshot(timed_out=False, nets=lustre.parse_lnet_net_show(stdout))


def _patch_efa_prereqs(
    monkeypatch,
    *,
    kefalnd_available=True,
    efa_driver_version="2.12.1",
    kefalnd_version="1.1.1",
    service_exists=False,
    service_failed=False,
):
    """Patch the EFA-prerequisite and systemd-service probes to healthy defaults for the data-path tests.

    The data-path EFA tests focus on device count / ping / traffic, so by default the kefalnd module is
    present, the versions meet the floors, and the systemd service is absent (the common PC compute-node
    case). Individual tests override a single kwarg to exercise a prerequisite/service failure.
    """
    monkeypatch.setattr(fsx_connectivity.efa, "efa_kefalnd_supported", lambda: kefalnd_available)
    monkeypatch.setattr(fsx_connectivity.efa, "efa_driver_version", lambda: efa_driver_version)
    monkeypatch.setattr(fsx_connectivity.efa, "efa_kefalnd_version", lambda: kefalnd_version)
    monkeypatch.setattr(fsx_connectivity.services, "systemd_unit_exists", lambda unit: service_exists)
    monkeypatch.setattr(fsx_connectivity.services, "systemd_unit_failed", lambda unit: service_failed)


# --- should_run gating ----------------------------------------------------------------


@pytest.mark.parametrize("check", [LustreFilesystem(), FsxTargetsAreReachable()])
@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_should_run_true_on_all_node_types_when_lustre_configured(check, node_type):
    assert check.should_run(sample_context_with_lustre(node_type)) is True


@pytest.mark.parametrize("check", [LustreFilesystem(), FsxTargetsAreReachable()])
def test_should_run_false_when_no_lustre_configured(check):
    assert check.should_run(sample_context(NodeType.HEAD)) is False


def test_description():
    description = LustreFilesystem().description
    assert "FsxLustre" in description or "Lustre" in description


# --- client probe ---------------------------------------------------------------------


def _patch_client(monkeypatch, *, available=True, loaded=True, version="2.15.6"):
    monkeypatch.setattr(fsx_connectivity.kernel_module, "kernel_module_available", lambda module: available)
    monkeypatch.setattr(fsx_connectivity.kernel_module, "kernel_module_loaded", lambda module: loaded)
    monkeypatch.setattr(fsx_connectivity.kernel_module, "kernel_release", lambda: "6.1.0-amzn2023")
    monkeypatch.setattr(fsx_connectivity.lustre, "lustre_client_version", lambda: version)


def test_client_modules_available_reports_version_and_no_error(monkeypatch):
    _patch_client(monkeypatch)
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD), errors, infos)

    assert errors == []
    assert _codes(infos) == [LustreFilesystem.CLIENT_VERSION.code]
    assert "2.15.6" in infos[0].message


def test_client_modules_unavailable_reports_only_not_installed(monkeypatch):
    # An unavailable module cannot be loaded either; the probe must report only the NOT_INSTALLED error
    # and NOT also MODULES_NOT_LOADED for the same root cause.
    _patch_client(monkeypatch, available=False, loaded=False, version=None)
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD), errors, infos)

    assert _codes(errors) == [LustreFilesystem.NOT_INSTALLED.code]
    assert "6.1.0-amzn2023" in _messages(errors)


def test_client_modules_available_but_not_loaded_fails(monkeypatch):
    _patch_client(monkeypatch, loaded=False)
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD), errors, infos)

    assert _codes(errors) == [LustreFilesystem.MODULES_NOT_LOADED.code]
    # The error names the specific modules that are available but not loaded.
    assert "lustre" in errors[0].message and "lnet" in errors[0].message


def test_client_too_old_version_fails(monkeypatch):
    # Default base_os (alinux2023) floor is 2.15; a 2.14 client is below it.
    _patch_client(monkeypatch, version="2.14.0")
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD), errors, infos)

    assert LustreFilesystem.CLIENT_TOO_OLD.code in _codes(errors)


def test_client_rhel8_2_12_meets_its_lower_floor(monkeypatch):
    # rhel8 ships the 2.12 client; the floor for rhel8 is 2.12, so 2.12.x must NOT be flagged too-old.
    _patch_client(monkeypatch, version="2.12.8")
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD, base_os="rhel8"), errors, infos)

    assert LustreFilesystem.CLIENT_TOO_OLD.code not in _codes(errors)


def test_client_rhel8_below_2_12_fails(monkeypatch):
    # Below even the rhel8 2.12 floor -> too old.
    _patch_client(monkeypatch, version="2.11.0")
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD, base_os="rhel8"), errors, infos)

    assert LustreFilesystem.CLIENT_TOO_OLD.code in _codes(errors)


def test_client_unknown_base_os_uses_default_floor(monkeypatch):
    # An unknown/missing base_os falls back to the 2.15 default, so a 2.14 client is flagged too-old.
    _patch_client(monkeypatch, version="2.14.0")
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD, base_os="mystery"), errors, infos)

    assert LustreFilesystem.CLIENT_TOO_OLD.code in _codes(errors)


def test_client_unparseable_version_reports_undeterminable_not_too_old(monkeypatch):
    # An unparseable (but present) version is not masked and not reported as too-old: it is surfaced as a
    # CHECK_ERROR (reserved E0) saying the floor could not be evaluated.
    _patch_client(monkeypatch, version="unknown")
    errors, infos = [], []

    LustreFilesystem()._probe_client(sample_context_with_lustre(NodeType.HEAD), errors, infos)

    assert LustreFilesystem.CLIENT_VERSION_UNDETERMINABLE.code in _codes(errors)
    assert LustreFilesystem.CLIENT_TOO_OLD.code not in _codes(errors)
    # The undeterminable finding carries the reserved E0 code -> CHECK_ERROR, not a real FAILURE.
    assert LustreFilesystem.CLIENT_VERSION_UNDETERMINABLE.code == "E0"


# --- mount-presence probe -------------------------------------------------------------


def _mounts_from(proc_mounts):
    from pcluster_diag.util.shared_storage import parse_proc_mounts

    parsed = parse_proc_mounts(proc_mounts)
    return lambda: parsed


def test_mounts_all_present_no_error(monkeypatch):
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_BOTH))
    errors = []

    LustreFilesystem()._probe_mounts(sample_context_with_lustre(NodeType.HEAD), errors)

    assert errors == []


def test_mounts_missing_one_fails_naming_only_that_mount(monkeypatch):
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_ONLY_FSX))
    errors = []

    LustreFilesystem()._probe_mounts(sample_context_with_lustre(NodeType.HEAD), errors)

    assert _codes(errors) == [LustreFilesystem.NOT_MOUNTED.code]
    assert "/fsx-efa" in _messages(errors)
    assert "'/fsx'" not in _messages(errors)


def test_mounts_none_present_fails_for_all(monkeypatch):
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(""))
    errors = []

    LustreFilesystem()._probe_mounts(sample_context_with_lustre(NodeType.HEAD), errors)

    assert _codes(errors) == [LustreFilesystem.NOT_MOUNTED.code, LustreFilesystem.NOT_MOUNTED.code]


# --- filesystem-reachability probe ----------------------------------------------------


def _patch_lfs(monkeypatch, results_by_mount):
    """Patch time_command to return a per-mount TimedCommand keyed by the mount dir argument."""

    def fake_time_command(command, timeout):
        mount_dir = command[-1]
        return results_by_mount[mount_dir]

    monkeypatch.setattr(fsx_connectivity, "time_command", fake_time_command)


def test_reachable_all_healthy_no_error(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {"/fsx": _timed(stdout=_HEALTHY_LFS_DF), "/fsx-efa": _timed(stdout=_HEALTHY_LFS_DF)},
    )
    errors = []

    LustreFilesystem()._probe_reachable(sample_context_with_lustre(NodeType.LOGIN), errors)

    assert errors == []


def test_reachable_hang_reports_timeout_for_only_that_mount(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {
            "/fsx": _timed(stdout=_HEALTHY_LFS_DF),
            "/fsx-efa": _timed(returncode=None, timed_out=True, elapsed=30.0),
        },
    )
    errors = []

    LustreFilesystem()._probe_reachable(sample_context_with_lustre(NodeType.COMPUTE), errors)

    assert _codes(errors) == [LustreFilesystem.LFS_DF_TIMED_OUT.code]
    assert "/fsx-efa" in _messages(errors)
    assert "hanging" in _messages(errors)


def test_reachable_nonzero_exit_reports_error(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {
            "/fsx": _timed(returncode=1, stderr="cannot send after transport endpoint shutdown"),
            "/fsx-efa": _timed(stdout=_HEALTHY_LFS_DF),
        },
    )
    errors = []

    LustreFilesystem()._probe_reachable(sample_context_with_lustre(NodeType.HEAD), errors)

    assert _codes(errors) == [LustreFilesystem.LFS_DF_FAILED.code]
    assert "transport endpoint shutdown" in _messages(errors)


def test_reachable_down_target_reports_target_unavailable(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {"/fsx": _timed(stdout=_DEGRADED_LFS_DF), "/fsx-efa": _timed(stdout=_HEALTHY_LFS_DF)},
    )
    errors = []

    LustreFilesystem()._probe_reachable(sample_context_with_lustre(NodeType.HEAD), errors)

    assert _codes(errors) == [LustreFilesystem.TARGET_UNAVAILABLE.code]
    assert "fs-abc-OST0001_UUID" in _messages(errors)
    assert "/fsx" in _messages(errors)


def test_reachable_aggregates_multiple_mount_failures(monkeypatch):
    _patch_lfs(
        monkeypatch,
        {
            "/fsx": _timed(returncode=None, timed_out=True, elapsed=30.0),
            "/fsx-efa": _timed(returncode=2, stderr="No such device"),
        },
    )
    errors = []

    LustreFilesystem()._probe_reachable(sample_context_with_lustre(NodeType.HEAD), errors)

    assert _codes(errors) == [
        LustreFilesystem.LFS_DF_TIMED_OUT.code,
        LustreFilesystem.LFS_DF_FAILED.code,
    ]


# --- shared fixtures for the LNet / EFA / target probes -------------------------------

_LNET_TCP_EFA = """\
net:
    - net type: lo
      local NI(s):
        - nid: 0@lo
          status: up
    - net type: tcp
      local NI(s):
        - nid: 10.0.0.1@tcp
          status: up
          interfaces:
              0: eth0
          statistics:
              send_count: 100
              recv_count: 100
          health stats:
              health value: 1000
    - net type: efa
      local NI(s):
        - nid: 10.0.0.1@efa
          status: up
          interfaces:
              0: efa0
          statistics:
              send_count: 900
              recv_count: 800
          health stats:
              health value: 1000
"""

_LNET_TCP_ONLY = """\
net:
    - net type: lo
      local NI(s):
        - nid: 0@lo
          status: up
    - net type: tcp
      local NI(s):
        - nid: 10.0.0.1@tcp
          status: up
          interfaces:
              0: eth0
          statistics:
              send_count: 100
              recv_count: 100
          health stats:
              health value: 1000
"""

# An @efa net with one device bound (efa0). A "partial bind" relative to a multi-device instance.
_LNET_EFA_PARTIAL_BIND = """\
net:
    - net type: efa
      local NI(s):
        - nid: 10.0.0.1@efa
          status: up
          interfaces:
              0: efa0
          statistics:
              send_count: 900
              recv_count: 800
          health stats:
              health value: 1000
"""

# An @efa net present but with no device bound to it (no interfaces): Lustre cannot ride EFA.
_LNET_EFA_NONE_BOUND = """\
net:
    - net type: efa
      local NI(s):
        - nid: 10.0.0.1@efa
          status: up
          statistics:
              send_count: 0
              recv_count: 0
          health stats:
              health value: 1000
"""

_LNET_EFA_NO_TRAFFIC = """\
net:
    - net type: efa
      local NI(s):
        - nid: 10.0.0.1@efa
          status: up
          interfaces:
              0: efa0
          statistics:
              send_count: 0
              recv_count: 0
          health stats:
              health value: 1000
        - nid: 10.0.0.2@efa
          status: up
          interfaces:
              0: efa1
          statistics:
              send_count: 10
              recv_count: 10
          health stats:
              health value: 1000
"""

_LNET_PEER_EFA = """\
peer:
    - primary nid: 10.0.1.5@efa
      peer ni:
        - nid: 10.0.1.5@efa
"""

_IMPORT_EFA = """\
osc.fs-OST0000-osc-ffff.import=
    import:
        target: fs-OST0000_UUID
        state: FULL
        connection:
            current_connection: 10.0.1.5@efa
            failover_nids: [ 10.0.1.5@efa ]
"""

_IMPORT_TCP_FALLBACK = """\
osc.fs-OST0000-osc-ffff.import=
    import:
        target: fs-OST0000_UUID
        state: FULL
        connection:
            current_connection: 10.0.1.5@tcp
            failover_nids: [ 10.0.1.5@tcp ]
"""

_IMPORT_DISCONN = """\
osc.fs-OST0000-osc-ffff.import=
    import:
        target: fs-OST0000_UUID
        state: DISCONN
        connection:
            current_connection: 10.0.1.5@efa
            failover_nids: [ 10.0.1.5@efa ]
"""

_LFS_CHECK_HEALTHY = "fs-OST0000-osc-ffff active.\nfs-MDT0000-mdc-ffff active.\n"
_LFS_CHECK_BAD = "fs-OST0000-osc-ffff active.\ncheck 'fs-OST000b-osc-ffff': Input/output error (5)\n"


def _route_time_command(monkeypatch, routes, default=None):
    """Patch time_command in every module that runs one, dispatching by substring match on the command.

    ``routes`` maps a substring (e.g. "net show", "peer show", "lfs check") to the TimedCommand to
    return. The first matching route wins; ``default`` (or a zero-exit empty result) is used otherwise.
    The check runs ``lfs``/``lctl`` commands via ``fsx_connectivity.time_command`` and the LNet peer/ping
    commands via ``lustre.time_command``, so both are patched with the same router.
    """
    from pcluster_diag.util import lustre

    def fake_time_command(command, timeout):
        joined = " ".join(command)
        for needle, timed in routes.items():
            if needle in joined:
                return timed
        return default if default is not None else _timed()

    monkeypatch.setattr(fsx_connectivity, "time_command", fake_time_command)
    monkeypatch.setattr(lustre, "time_command", fake_time_command)
    # Tests that route commands through time_command intend for those binaries to be present, so make the
    # lnetctl presence gate in _lnet_snapshot pass (the real which() would depend on the test host).
    monkeypatch.setattr(fsx_connectivity.shutil, "which", lambda name: "/usr/sbin/" + name)


# --- LNet-transport probe -------------------------------------------------------------


def test_lnet_reports_active_lnds_no_error(monkeypatch):
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_lnet(_snapshot(_LNET_TCP_EFA), errors, warnings, infos)

    assert errors == []
    active_info = next(i for i in infos if i.code == LustreFilesystem.ACTIVE_LNDS.code)
    assert "tcp" in active_info.message and "efa" in active_info.message
    # loopback is not reported as an active transport
    assert "lo" not in active_info.message.split("transports:")[1]


def test_lnet_no_nets_fails(monkeypatch):
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_lnet(_snapshot("net:\n"), errors, warnings, infos)

    assert _codes(errors) == [LustreFilesystem.LNET_NOT_CONFIGURED.code]


def test_lnet_timeout_fails_with_timeout_code():
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_lnet(_LnetSnapshot(timed_out=True), errors, warnings, infos)

    assert _codes(errors) == [LustreFilesystem.LNETCTL_TIMED_OUT.code]


def test_lnet_unavailable_lnetctl_is_info_not_error():
    # lnetctl not installed: report an info and skip, without failing the check.
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_lnet(_LnetSnapshot(timed_out=False, unavailable=True), errors, warnings, infos)

    assert errors == []
    assert LustreFilesystem.LNETCTL_UNAVAILABLE.code in _codes(infos)


def test_efa_probe_noop_when_lnetctl_unavailable():
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE),
        _LnetSnapshot(timed_out=False, unavailable=True),
        errors,
        warnings,
        infos,
    )

    assert errors == [] and warnings == [] and infos == []


def test_efa_probe_skipped_on_efa_unsupported_os(monkeypatch):
    # rhel8 does not support EFA-for-Lustre: the probe reports an info and runs no EFA data-path probes.
    def _boom_device_count():
        raise AssertionError("EFA data-path probe must not run on an EFA-unsupported OS")

    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", _boom_device_count)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE, base_os="rhel8"),
        _snapshot(_LNET_TCP_EFA),
        errors,
        warnings,
        infos,
    )

    assert errors == [] and warnings == []
    assert LustreFilesystem.EFA_NOT_SUPPORTED_ON_OS.code in _codes(infos)


def test_lnet_health_decay_is_warning(monkeypatch):
    decayed = _LNET_EFA_NO_TRAFFIC.replace("health value: 1000", "health value: 500", 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_lnet(_snapshot(decayed), errors, warnings, infos)

    assert _codes(warnings) == [LustreFilesystem.HEALTH_DEGRADED.code]


# --- EFA-mount probe ------------------------------------------------------------------


def test_efa_probe_noop_without_efa_net_or_service(monkeypatch):
    # Neither an @efa net nor the EFA-Lustre service on this node: EFA is not expected, so record nothing.
    monkeypatch.setattr(fsx_connectivity.services, "systemd_unit_exists", lambda unit: False)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_ONLY), errors, warnings, infos
    )

    assert errors == [] and warnings == [] and infos == []


def test_efa_missing_kefalnd_caught_when_service_installed_but_no_efa_net(monkeypatch):
    # The regression this guards: kefalnd failed to load -> no @efa net is ever added. Gating on the @efa
    # net alone would skip the node. The installed systemd service is the node-local "EFA expected" signal
    # that survives the kefalnd failure, so KEFALND_MISSING is still reported despite there being no @efa net.
    _patch_efa_prereqs(monkeypatch, kefalnd_available=False, service_exists=True)

    def _boom_device_count():
        raise AssertionError("data-path probe must not run when kefalnd is missing")

    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", _boom_device_count)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_ONLY), errors, warnings, infos
    )

    assert _codes(errors) == [LustreFilesystem.KEFALND_MISSING.code]


def test_efa_probe_noop_when_lnet_timed_out():
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _LnetSnapshot(timed_out=True), errors, warnings, infos
    )

    assert errors == [] and warnings == [] and infos == []


def test_efa_all_bound_and_pinging_no_error(monkeypatch):
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ping ok"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert errors == []
    assert LustreFilesystem.BOUND_DEVICES.code in _codes(infos)


def test_efa_partial_bind_on_unknown_instance_type_is_not_an_error(monkeypatch):
    # 1 of 16 bound on an instance type with no expected-count entry (the sample context's fake type):
    # we make no underbinding assertion, so it is an info + pass, not an error.
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ping ok"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 16)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_EFA_PARTIAL_BIND), errors, warnings, infos
    )

    assert LustreFilesystem.NO_DEVICES_BOUND.code not in _codes(errors)
    assert LustreFilesystem.UNDERBOUND_DEVICES.code not in _codes(errors)
    assert LustreFilesystem.BOUND_DEVICES.code in _codes(infos)
    assert "1 of 16" in _messages(infos)


def test_efa_underbound_fails_when_expected_equals_available(monkeypatch):
    # p6-b300.48xlarge expects 16 bound (per the FSx doc); only 1 of 16 bound is the incident signature.
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ping ok"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 16)
    context = sample_context_with_lustre(NodeType.COMPUTE)
    context.instance_type = "p6-b300.48xlarge"
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(context, _snapshot(_LNET_EFA_PARTIAL_BIND), errors, warnings, infos)

    assert LustreFilesystem.UNDERBOUND_DEVICES.code in _codes(errors)
    assert "1 of 16" in _messages(errors)


def test_efa_subset_bind_family_meeting_expected_passes(monkeypatch):
    # p5.48xlarge binds 8 by design. With 8 of 16 bound, the expected count is met -> pass, no error.
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ping ok"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 16)
    eight_bound = ["efa%d" % i for i in range(8)]
    monkeypatch.setattr(fsx_connectivity.lustre, "lnet_bound_interfaces", lambda nets, net_type: eight_bound)
    context = sample_context_with_lustre(NodeType.COMPUTE)
    context.instance_type = "p5.48xlarge"
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(context, _snapshot(_LNET_EFA_PARTIAL_BIND), errors, warnings, infos)

    assert LustreFilesystem.UNDERBOUND_DEVICES.code not in _codes(errors)
    assert LustreFilesystem.NO_DEVICES_BOUND.code not in _codes(errors)
    assert LustreFilesystem.BOUND_DEVICES.code in _codes(infos)


def test_efa_no_devices_bound_fails(monkeypatch):
    # EFA devices exist but none are bound to LNet: Lustre falls back to TCP -- a real failure on any family.
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ping ok"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 16)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_EFA_NONE_BOUND), errors, warnings, infos
    )

    assert LustreFilesystem.NO_DEVICES_BOUND.code in _codes(errors)
    assert "16" in _messages(errors)


def test_efa_ping_failure_points_at_security_group(monkeypatch):
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(returncode=1, stderr="cannot reach"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert LustreFilesystem.EFA_PING_FAILED.code in _codes(errors)
    assert "security group" in _messages(errors)


def test_efa_no_traffic_is_warning(monkeypatch):
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ok"),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 2)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_EFA_NO_TRAFFIC), errors, warnings, infos
    )

    assert LustreFilesystem.NO_TRAFFIC.code in _codes(warnings)


def test_efa_import_over_tcp_is_not_a_finding(monkeypatch):
    # A healthy EFA client reads @tcp in its import (FSx documents the mount target as @tcp and Multi-Rail
    # picks the rail below ptlrpc), so the import transport must not produce a finding.
    _patch_efa_prereqs(monkeypatch)
    _route_time_command(
        monkeypatch,
        {
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ok"),
            "import": _timed(stdout=_IMPORT_TCP_FALLBACK),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert LustreFilesystem.TCP_FALLBACK.code not in _codes(warnings)


# --- EFA prerequisites & systemd service (checked before the data-path probes) --------


def test_efa_missing_kefalnd_fails_and_skips_data_path(monkeypatch):
    # kefalnd absent: the client cannot ride EFA; report KEFALND_MISSING and do not probe devices/ping.
    _patch_efa_prereqs(monkeypatch, kefalnd_available=False)

    def _boom_device_count():
        raise AssertionError("data-path probe must not run when kefalnd is missing")

    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", _boom_device_count)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert _codes(errors) == [LustreFilesystem.KEFALND_MISSING.code]


def test_efa_driver_too_old_fails(monkeypatch):
    _patch_efa_prereqs(monkeypatch, efa_driver_version="2.10.0")
    _route_time_command(
        monkeypatch,
        {"peer show": _timed(stdout=_LNET_PEER_EFA), "ping": _timed(stdout="ok"), "import": _timed(stdout=_IMPORT_EFA)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert LustreFilesystem.EFA_DRIVER_TOO_OLD.code in _codes(errors)


def test_efa_kefalnd_too_old_only_on_p6(monkeypatch):
    # kefalnd below the p6 floor: flagged on a p6 instance, not on a non-p6 instance.
    _patch_efa_prereqs(monkeypatch, kefalnd_version="1.0.0")
    _route_time_command(
        monkeypatch,
        {"peer show": _timed(stdout=_LNET_PEER_EFA), "ping": _timed(stdout="ok"), "import": _timed(stdout=_IMPORT_EFA)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)

    p6 = sample_context_with_lustre(NodeType.COMPUTE)
    p6.instance_type = _FAKE_P6PLUS_INSTANCE_TYPE
    errors, warnings, infos = [], [], []
    LustreFilesystem()._probe_efa(p6, _snapshot(_LNET_TCP_EFA), errors, warnings, infos)
    assert LustreFilesystem.KEFALND_TOO_OLD.code in _codes(errors)

    non_p6 = sample_context_with_lustre(NodeType.COMPUTE)
    non_p6.instance_type = _FAKE_NON_P6_INSTANCE_TYPE
    errors, warnings, infos = [], [], []
    LustreFilesystem()._probe_efa(non_p6, _snapshot(_LNET_TCP_EFA), errors, warnings, infos)
    assert LustreFilesystem.KEFALND_TOO_OLD.code not in _codes(errors)


def test_efa_unknown_instance_type_reports_undeterminable_not_too_old(monkeypatch):
    # Instance type unknown (IMDS failed at startup): the p6+ kefalnd floor cannot be evaluated. The probe
    # must surface a CHECK_ERROR (reserved E0) rather than flag a too-old error or silently pass.
    _patch_efa_prereqs(monkeypatch, kefalnd_version="1.0.0")
    _route_time_command(
        monkeypatch,
        {"peer show": _timed(stdout=_LNET_PEER_EFA), "ping": _timed(stdout="ok"), "import": _timed(stdout=_IMPORT_EFA)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)

    unknown = sample_context_with_lustre(NodeType.COMPUTE)
    unknown.instance_type = None
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(unknown, _snapshot(_LNET_TCP_EFA), errors, warnings, infos)

    assert LustreFilesystem.INSTANCE_TYPE_UNDETERMINABLE.code in _codes(errors)
    assert LustreFilesystem.INSTANCE_TYPE_UNDETERMINABLE.code == "E0"
    assert LustreFilesystem.KEFALND_TOO_OLD.code not in _codes(errors)


def test_efa_driver_version_unparseable_reports_undeterminable_not_too_old(monkeypatch):
    # A present-but-unparseable EFA driver version is surfaced as a CHECK_ERROR (E0), not a too-old error.
    _patch_efa_prereqs(monkeypatch, efa_driver_version="unknown")
    _route_time_command(
        monkeypatch,
        {"peer show": _timed(stdout=_LNET_PEER_EFA), "ping": _timed(stdout="ok"), "import": _timed(stdout=_IMPORT_EFA)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert LustreFilesystem.EFA_DRIVER_VERSION_UNDETERMINABLE.code in _codes(errors)
    assert LustreFilesystem.EFA_DRIVER_TOO_OLD.code not in _codes(errors)


def test_efa_service_failed_is_error(monkeypatch):
    _patch_efa_prereqs(monkeypatch, service_exists=True, service_failed=True)
    _route_time_command(
        monkeypatch,
        {"peer show": _timed(stdout=_LNET_PEER_EFA), "ping": _timed(stdout="ok"), "import": _timed(stdout=_IMPORT_EFA)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert LustreFilesystem.EFA_SERVICE_FAILED.code in _codes(errors)


def test_efa_service_failed_without_efa_net_reports_service_and_skips_data_path(monkeypatch):
    # The config service is installed but failed, so no @efa net came up. The service failure is reported
    # and the data-path probes are skipped (there is no live net to inspect).
    _patch_efa_prereqs(monkeypatch, service_exists=True, service_failed=True)

    def _boom_device_count():
        raise AssertionError("data-path probe must not run when there is no @efa net")

    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", _boom_device_count)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_ONLY), errors, warnings, infos
    )

    assert LustreFilesystem.EFA_SERVICE_FAILED.code in _codes(errors)


def test_efa_service_present_and_healthy_is_info(monkeypatch):
    _patch_efa_prereqs(monkeypatch, service_exists=True, service_failed=False)
    _route_time_command(
        monkeypatch,
        {"peer show": _timed(stdout=_LNET_PEER_EFA), "ping": _timed(stdout="ok"), "import": _timed(stdout=_IMPORT_EFA)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)
    errors, warnings, infos = [], [], []

    LustreFilesystem()._probe_efa(
        sample_context_with_lustre(NodeType.COMPUTE), _snapshot(_LNET_TCP_EFA), errors, warnings, infos
    )

    assert LustreFilesystem.EFA_SERVICE_ACTIVE.code in _codes(infos)


# --- run-level aggregation & isolation ------------------------------------------------


def test_run_passes_when_all_probes_clean(monkeypatch):
    _patch_client(monkeypatch)
    _patch_efa_prereqs(monkeypatch)
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_BOTH))
    _route_time_command(
        monkeypatch,
        {
            "net show": _timed(stdout=_LNET_TCP_EFA),
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ok"),
            "import": _timed(stdout=_IMPORT_EFA),
            "df": _timed(stdout=_HEALTHY_LFS_DF),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)

    result = LustreFilesystem().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.PASSED


def test_run_is_check_error_not_failure_when_only_undeterminable(monkeypatch):
    # Everything healthy except the instance type is unknown (IMDS error). The undeterminable finding is an
    # E0 error, so the aggregate status is CHECK_ERROR (the check could not fully evaluate), NOT FAILURE
    # (no real assertion failed) -- error and failure are distinct sections.
    _patch_client(monkeypatch)
    _patch_efa_prereqs(monkeypatch, kefalnd_version="1.0.0")
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_BOTH))
    _route_time_command(
        monkeypatch,
        {
            "net show": _timed(stdout=_LNET_TCP_EFA),
            "peer show": _timed(stdout=_LNET_PEER_EFA),
            "ping": _timed(stdout="ok"),
            "import": _timed(stdout=_IMPORT_EFA),
            "df": _timed(stdout=_HEALTHY_LFS_DF),
        },
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)

    unknown = sample_context_with_lustre(NodeType.COMPUTE)
    unknown.instance_type = None  # IMDS could not report the instance type
    result = LustreFilesystem().run(unknown)

    assert result.status is Status.CHECK_ERROR
    assert LustreFilesystem.INSTANCE_TYPE_UNDETERMINABLE.code in _codes(result.errors)


def test_run_fails_when_any_probe_reports_an_error(monkeypatch):
    _patch_client(monkeypatch, available=False, version=None)  # client probe fails
    _patch_efa_prereqs(monkeypatch)
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_BOTH))
    _route_time_command(
        monkeypatch,
        {"net show": _timed(stdout=_LNET_TCP_ONLY), "df": _timed(stdout=_HEALTHY_LFS_DF)},
    )

    result = LustreFilesystem().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert LustreFilesystem.NOT_INSTALLED.code in _codes(result.errors)


def test_run_isolates_unexpected_probe_crash_and_keeps_sibling_findings(monkeypatch):
    # The client probe crashes; its siblings must still run and their findings survive.
    def _boom(errors, infos):
        raise RuntimeError("boom")

    monkeypatch.setattr(LustreFilesystem, "_probe_client", lambda self, errors, infos: _boom(errors, infos))
    _patch_efa_prereqs(monkeypatch)
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_ONLY_FSX))
    _route_time_command(
        monkeypatch,
        {"net show": _timed(stdout=_LNET_TCP_EFA), "df": _timed(stdout=_HEALTHY_LFS_DF)},
    )
    monkeypatch.setattr(fsx_connectivity.efa, "efa_device_count", lambda: 1)

    result = LustreFilesystem().run(sample_context_with_lustre(NodeType.COMPUTE))

    # The mount probe still reported the missing /fsx-efa mount despite the client probe crashing.
    assert result.status is Status.FAILURE
    assert LustreFilesystem.NOT_MOUNTED.code in _codes(result.errors)


def test_run_missing_lnetctl_does_not_sink_other_probes(monkeypatch):
    # lnetctl is not installed (shutil.which returns None). This must NOT abort the whole check: the LNet
    # snapshot is marked unavailable, the LNet probe records an info and skips, the EFA probe no-ops, and
    # the mount/reachability probes still run and report their findings.
    _patch_client(monkeypatch)
    monkeypatch.setattr(fsx_connectivity.shared_storage, "read_mounts", _mounts_from(_PROC_MOUNTS_BOTH))
    _route_time_command(monkeypatch, {"df": _timed(stdout=_HEALTHY_LFS_DF)})
    # Override the helper's truthy which(): lnetctl is not installed on this node.
    monkeypatch.setattr(fsx_connectivity.shutil, "which", lambda name: None)

    result = LustreFilesystem().run(sample_context_with_lustre(NodeType.COMPUTE))

    # The check completed (was not aborted by the missing binary) and surfaced the lnetctl-unavailable info.
    assert LustreFilesystem.LNETCTL_UNAVAILABLE.code in _codes(result.infos)
    # A sibling probe (mount presence) still ran: both /fsx and /fsx-efa are present, so no NOT_MOUNTED.
    assert LustreFilesystem.NOT_MOUNTED.code not in _codes(result.errors)


# --- FsxTargetsAreReachable (kept, but not registered) --------------------------------


def test_targets_description():
    assert "OST" in FsxTargetsAreReachable().description


def test_targets_requires_approval():
    assert FsxTargetsAreReachable().approval_required(sample_context_with_lustre(NodeType.HEAD)) is True


def test_targets_all_active_and_full_passes(monkeypatch):
    _route_time_command(
        monkeypatch,
        {"lfs check": _timed(stdout=_LFS_CHECK_HEALTHY), "import": _timed(stdout=_IMPORT_EFA)},
    )

    result = FsxTargetsAreReachable().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.PASSED


def test_targets_unreachable_server_fails(monkeypatch):
    _route_time_command(
        monkeypatch,
        {"lfs check": _timed(stdout=_LFS_CHECK_BAD), "import": _timed(stdout=_IMPORT_EFA)},
    )

    result = FsxTargetsAreReachable().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert FsxTargetsAreReachable.TARGET_UNREACHABLE.code in _codes(result.errors)
    assert "fs-OST000b-osc-ffff" in _messages(result.errors)


def test_targets_lfs_check_timeout_fails(monkeypatch):
    _route_time_command(
        monkeypatch,
        {
            "lfs check": _timed(returncode=None, timed_out=True, elapsed=60.0),
            "import": _timed(stdout=_IMPORT_EFA),
        },
    )

    result = FsxTargetsAreReachable().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert _codes(result.errors) == [FsxTargetsAreReachable.LFS_CHECK_TIMED_OUT.code]


def test_targets_non_full_import_fails(monkeypatch):
    _route_time_command(
        monkeypatch,
        {"lfs check": _timed(stdout=_LFS_CHECK_HEALTHY), "import": _timed(stdout=_IMPORT_DISCONN)},
    )

    result = FsxTargetsAreReachable().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert FsxTargetsAreReachable.IMPORT_NOT_FULL.code in _codes(result.errors)
    assert "DISCONN" in _messages(result.errors)


def test_targets_failover_pin_is_info(monkeypatch):
    _route_time_command(
        monkeypatch,
        {"lfs check": _timed(stdout=_LFS_CHECK_HEALTHY), "import": _timed(stdout=_IMPORT_EFA)},
    )

    result = FsxTargetsAreReachable().run(sample_context_with_lustre(NodeType.COMPUTE))

    assert result.status is Status.PASSED
    assert FsxTargetsAreReachable.FAILOVER_PINNED.code in _info_codes(result)
