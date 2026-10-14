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

"""Unit tests for the ENA network counter readers (primary interface, ethtool -S)."""

import subprocess

import pytest

from pcluster_diag.util import network_counters

_ROUTE_TABLE = (
    "Iface\tDestination\tGateway \tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT\n"
    "ens5\t0010A8C0\t00000000\t0001\t0\t0\t0\t00F0FFFF\t0\t0\t0\n"
    "ens5\t00000000\t0110A8C0\t0003\t0\t0\t0\t00000000\t0\t0\t0\n"
)

_ETHTOOL_OUTPUT = """NIC statistics:
     tx_timeout: 0
     bw_in_allowance_exceeded: 12
     bw_out_allowance_exceeded: 0
     pps_allowance_exceeded: 3
     conntrack_allowance_exceeded: 0
     linklocal_allowance_exceeded: 7
     conntrack_allowance_available: 136812
     queue_0_tx_cnt: 123
"""


def _write(path, content):
    path.write_text(content, encoding="utf-8")
    return str(path)


def test_primary_interface_reads_default_route(tmp_path, monkeypatch):
    monkeypatch.setattr(network_counters, "PROC_NET_ROUTE_PATH", _write(tmp_path / "route", _ROUTE_TABLE))
    assert network_counters.primary_interface() == "ens5"


def test_primary_interface_falls_back_to_known_names(tmp_path, monkeypatch):
    monkeypatch.setattr(network_counters, "PROC_NET_ROUTE_PATH", str(tmp_path / "missing"))
    monkeypatch.setattr(network_counters.os.path, "exists", lambda path: path == "/sys/class/net/eth0")
    assert network_counters.primary_interface() == "eth0"


def test_primary_interface_none_when_nothing_found(tmp_path, monkeypatch):
    monkeypatch.setattr(network_counters, "PROC_NET_ROUTE_PATH", str(tmp_path / "missing"))
    monkeypatch.setattr(network_counters.os.path, "exists", lambda path: False)
    assert network_counters.primary_interface() is None


def test_parse_ethtool_statistics_keeps_only_allowance_counters():
    counters = network_counters.parse_ethtool_statistics(_ETHTOOL_OUTPUT, network_counters.ENA_ALLOWANCE_COUNTERS)
    assert counters == {
        "bw_in_allowance_exceeded": 12,
        "bw_out_allowance_exceeded": 0,
        "pps_allowance_exceeded": 3,
        "conntrack_allowance_exceeded": 0,
        "linklocal_allowance_exceeded": 7,
    }


def test_parse_ethtool_statistics_ignores_non_numeric_values():
    counters = network_counters.parse_ethtool_statistics("  pps_allowance_exceeded: n/a\n", ("pps_allowance_exceeded",))
    assert counters == {}


def test_ena_allowance_counters_runs_ethtool(monkeypatch):
    calls = []

    def _run(command, **_kwargs):
        calls.append(command)
        return subprocess.CompletedProcess(command, 0, stdout=_ETHTOOL_OUTPUT, stderr="")

    monkeypatch.setattr(network_counters.shell, "run_command", _run)

    counters = network_counters.ena_allowance_counters("eth0")

    assert calls == [["/usr/sbin/ethtool", "-S", "eth0"]]
    assert counters["linklocal_allowance_exceeded"] == 7
    assert "queue_0_tx_cnt" not in counters


@pytest.mark.parametrize(
    "run_command",
    [
        lambda command, **_kwargs: subprocess.CompletedProcess(command, 1, stdout="", stderr="no such device"),
        lambda command, **_kwargs: (_ for _ in ()).throw(FileNotFoundError("ethtool")),
    ],
    ids=["non_zero_exit", "ethtool_missing"],
)
def test_ena_allowance_counters_none_when_ethtool_fails(monkeypatch, run_command):
    monkeypatch.setattr(network_counters.shell, "run_command", run_command)
    assert network_counters.ena_allowance_counters("eth0") is None
