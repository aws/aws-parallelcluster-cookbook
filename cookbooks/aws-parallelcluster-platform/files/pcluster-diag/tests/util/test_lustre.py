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

"""Unit tests for the Lustre-specific helpers: lfs df parsing and client detection."""

from pcluster_diag.util import kernel_module, lustre
from tests.test_helpers import DEGRADED_LFS_DF as _DEGRADED_LFS_DF
from tests.test_helpers import HEALTHY_LFS_DF as _HEALTHY_LFS_DF
from tests.test_helpers import completed_process as _completed

# --- lfs df -h parsing ----------------------------------------------------------------


def test_parse_lfs_df_healthy_all_targets_available():
    targets = lustre.parse_lfs_df(_HEALTHY_LFS_DF)

    assert [t.uuid for t in targets] == [
        "fs-abc-MDT0000_UUID",
        "fs-abc-OST0000_UUID",
        "fs-abc-OST0001_UUID",
    ]
    assert all(t.available for t in targets)
    assert [t.role for t in targets] == ["MDT", "OST", "OST"]


def test_unavailable_targets_flags_errored_target():
    unavailable = lustre.unavailable_targets(_DEGRADED_LFS_DF)

    assert [t.uuid for t in unavailable] == ["fs-abc-OST0001_UUID"]
    assert unavailable[0].role == "OST"
    assert "Resource temporarily unavailable" in unavailable[0].detail


def test_unavailable_targets_empty_when_all_healthy():
    assert lustre.unavailable_targets(_HEALTHY_LFS_DF) == []


def test_parse_lfs_df_ignores_header_and_summary():
    targets = lustre.parse_lfs_df(_HEALTHY_LFS_DF)

    assert all("filesystem_summary" not in t.uuid and t.uuid != "UUID" for t in targets)


def test_parse_lfs_df_skips_non_target_lines():
    # A body line that is neither a capacity row nor names a target role is ignored.
    assert lustre.parse_lfs_df("some random note line\n\n") == []


def test_parse_lfs_df_skips_single_token_line():
    # A body line with fewer than two tokens is not a parseable target row.
    assert lustre.parse_lfs_df("loneword\n") == []


# --- Lustre client version (delegates to util.kernel_module) -------------------------------


def test_lustre_client_version_from_modinfo(monkeypatch):
    monkeypatch.setattr(kernel_module, "run_command", lambda command: _completed(stdout="2.15.6\n"))

    assert lustre.lustre_client_version() == "2.15.6"


def test_lustre_client_version_none_on_failure(monkeypatch):
    monkeypatch.setattr(kernel_module, "run_command", lambda command: _completed(returncode=1))

    assert lustre.lustre_client_version() is None


# --- lnetctl net show parsing ---------------------------------------------------------

# `lnetctl net show -v` with a loopback net, a tcp net, and an EFA net (two bound devices) with stats.
_LNET_NET_SHOW = """\
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
              send_count: 1200
              recv_count: 1500
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
        - nid: 10.0.0.2@efa
          status: up
          interfaces:
              0: efa1
          statistics:
              send_count: 0
              recv_count: 0
          health stats:
              health value: 640
"""


def test_parse_lnet_net_show_lists_nets_and_nis():
    nets = lustre.parse_lnet_net_show(_LNET_NET_SHOW)

    assert [net.net_type for net in nets] == ["lo", "tcp", "efa"]
    efa = lustre.lnet_net(nets, "efa")
    assert [ni.nid for ni in efa.local_nis] == ["10.0.0.1@efa", "10.0.0.2@efa"]
    assert efa.local_nis[0].send_count == 900
    assert efa.local_nis[1].health_value == 640


def test_active_lnds_excludes_loopback():
    nets = lustre.parse_lnet_net_show(_LNET_NET_SHOW)

    assert lustre.active_lnds(nets) == ["tcp", "efa"]


def test_lnet_bound_interfaces_collects_devices():
    nets = lustre.parse_lnet_net_show(_LNET_NET_SHOW)

    assert lustre.lnet_bound_interfaces(nets, "efa") == ["efa0", "efa1"]
    assert lustre.lnet_bound_interfaces(nets, "o2ib") == []


def test_local_nids_returns_net_nids():
    nets = lustre.parse_lnet_net_show(_LNET_NET_SHOW)

    assert lustre.local_nids(nets, "efa") == ["10.0.0.1@efa", "10.0.0.2@efa"]
    assert lustre.local_nids(nets, "o2ib") == []


def test_parse_lnet_net_show_empty_on_no_nets():
    assert lustre.parse_lnet_net_show("net:\n") == []


def test_parse_lnet_net_show_empty_on_garbage():
    assert lustre.parse_lnet_net_show(": : not yaml : :\n- [") == []


# --- lnetctl peer show parsing --------------------------------------------------------

_LNET_PEER_SHOW = """\
peer:
    - primary nid: 10.0.1.5@efa
      peer ni:
        - nid: 10.0.1.5@efa
        - nid: 10.0.1.5@tcp
    - primary nid: 10.0.1.6@tcp
      peer ni:
        - nid: 10.0.1.6@tcp
"""


def test_parse_lnet_peer_show_collects_nids():
    nids = lustre.parse_lnet_peer_show(_LNET_PEER_SHOW)

    assert "10.0.1.5@efa" in nids
    assert "10.0.1.6@tcp" in nids


def test_nids_on_net_filters_and_dedupes():
    nids = lustre.parse_lnet_peer_show(_LNET_PEER_SHOW)

    assert lustre.nids_on_net(nids, "efa") == ["10.0.1.5@efa"]


def test_parse_lnet_peer_show_empty_on_garbage():
    assert lustre.parse_lnet_peer_show("- [") == []


# --- lfs check servers parsing --------------------------------------------------------

_LFS_CHECK_SERVERS = """\
fs-MDT0000-mdc-ffff active.
fs-OST0000-osc-ffff active.
check 'fs-OST000b-osc-ffff': Input/output error (5)
"""


def test_parse_lfs_check_servers_classifies_active_and_errored():
    servers = lustre.parse_lfs_check_servers(_LFS_CHECK_SERVERS)

    assert [s.target for s in servers] == [
        "fs-MDT0000-mdc-ffff",
        "fs-OST0000-osc-ffff",
        "fs-OST000b-osc-ffff",
    ]
    assert [s.active for s in servers] == [True, True, False]


def test_unreachable_servers_flags_only_errored():
    unreachable = lustre.unreachable_servers(_LFS_CHECK_SERVERS)

    assert [s.target for s in unreachable] == ["fs-OST000b-osc-ffff"]
    assert "Input/output error" in unreachable[0].detail


def test_unreachable_servers_empty_when_all_active():
    assert lustre.unreachable_servers("fs-OST0000-osc-ffff active.\n") == []


# --- LNet ping (lnetctl peer show + ping) ---------------------------------------------


def test_efa_peer_nids_returns_all_efa_peers(monkeypatch):
    two_efa_peers = (
        "peer:\n"
        "    - primary nid: 10.0.1.5@efa\n      peer ni:\n        - nid: 10.0.1.5@efa\n"
        "    - primary nid: 10.0.1.6@efa\n      peer ni:\n        - nid: 10.0.1.6@efa\n"
    )
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(stdout=two_efa_peers))
    assert lustre.efa_peer_nids() == ["10.0.1.5@efa", "10.0.1.6@efa"]


def test_efa_peer_nids_empty_on_command_failure(monkeypatch):
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(returncode=1))
    assert lustre.efa_peer_nids() == []


def test_efa_peer_nid_returns_first_efa_peer(monkeypatch):
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(stdout=_LNET_PEER_SHOW))
    assert lustre.efa_peer_nid() == "10.0.1.5@efa"


def test_efa_peer_nid_none_when_no_efa_peer(monkeypatch):
    tcp_only_peer = "peer:\n    - primary nid: 1.2.3.4@tcp\n"
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(stdout=tcp_only_peer))
    assert lustre.efa_peer_nid() is None


def test_efa_peer_nid_none_on_command_failure(monkeypatch):
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(returncode=1))
    assert lustre.efa_peer_nid() is None


def test_efa_ping_works_true_on_success(monkeypatch):
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(stdout="ok"))
    assert lustre.efa_ping_works("10.0.0.1@efa", "10.0.1.5@efa") is True


def test_efa_ping_works_false_on_nonzero_or_timeout(monkeypatch):
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: _completed_timed(returncode=1))
    assert lustre.efa_ping_works("10.0.0.1@efa", "10.0.1.5@efa") is False
    hung = _completed_timed(timed_out=True, returncode=None)
    monkeypatch.setattr(lustre, "time_command", lambda command, timeout: hung)
    assert lustre.efa_ping_works("10.0.0.1@efa", "10.0.1.5@efa") is False


def _completed_timed(returncode=0, stdout="", stderr="", timed_out=False):
    """Build a TimedCommand double for the lnetctl peer/ping helpers."""
    from pcluster_diag.util.shell import TimedCommand

    return TimedCommand(
        command=["lnetctl"],
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
        elapsed_seconds=0.01,
        timed_out=timed_out,
    )
