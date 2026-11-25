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

"""Unit tests for the listening TCP ports reader."""

from pcluster_diag.util import listening_ports
from pcluster_diag.util.listening_ports import parse_listening_ports

_PROC_NET_TCP = """\
  sl  local_address rem_address   st tx_queue rx_queue tr tm->when retrnsmt   uid  timeout inode
   0: 00000000:0801 00000000:0000 0A 00000000:00000000 00:00000000 00000000     0        0 1 1
   1: 00000000:1AA4 00000000:0000 0A 00000000:00000000 00:00000000 00000000   401        0 2 1
   2: 0A00000A:0016 0A000014:C350 01 00000000:00000000 02:000A7B2C 00000000     0        0 3 1
   3: garbage
"""

_PROC_NET_TCP6 = """\
  sl  local_address                         remote_address                        st tx_queue rx_queue
   0: 00000000000000000000000000000000:1AA2 00000000000000000000000000000000:0000 0A 00000000:00000000
   1: 00000000000000000000000000000000:ZZZZ 00000000000000000000000000000000:0000 0A 00000000:00000000
"""


def test_parse_listening_ports_keeps_listen_sockets_only():
    # 0x0801 = 2049 (NFS), 0x1AA4 = 6820 (slurmctld); the ESTABLISHED ssh socket (0x0016) is ignored.
    assert parse_listening_ports(_PROC_NET_TCP) == {2049, 6820}


def test_parse_listening_ports_reads_ipv6_and_skips_bad_ports():
    assert parse_listening_ports(_PROC_NET_TCP6) == {6818}


def test_listening_tcp_ports_merges_ipv4_and_ipv6(monkeypatch, tmp_path):
    tcp, tcp6 = tmp_path / "tcp", tmp_path / "tcp6"
    tcp.write_text(_PROC_NET_TCP, encoding="utf-8")
    tcp6.write_text(_PROC_NET_TCP6, encoding="utf-8")
    monkeypatch.setattr(listening_ports, "PROC_NET_TCP_PATHS", (str(tcp), str(tcp6)))

    assert listening_ports.listening_tcp_ports() == {2049, 6818, 6820}


def test_listening_tcp_ports_tolerates_one_missing_table(monkeypatch, tmp_path):
    tcp = tmp_path / "tcp"
    tcp.write_text(_PROC_NET_TCP, encoding="utf-8")
    monkeypatch.setattr(listening_ports, "PROC_NET_TCP_PATHS", (str(tcp), str(tmp_path / "missing")))

    assert listening_ports.listening_tcp_ports() == {2049, 6820}


def test_listening_tcp_ports_returns_none_when_nothing_readable(monkeypatch, tmp_path):
    monkeypatch.setattr(listening_ports, "PROC_NET_TCP_PATHS", (str(tmp_path / "a"), str(tmp_path / "b")))

    assert listening_ports.listening_tcp_ports() is None
