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

"""Unit tests for the pure socket helpers that turn network failures into data rather than exceptions."""

import socket

from pcluster_diag.util import network


def test_resolve_host_succeeds(monkeypatch):
    monkeypatch.setattr(network.socket, "getaddrinfo", lambda host, port: [("family", "socktype")])

    result = network.resolve_host("db.example.com")

    assert result.resolved is True
    assert result.error is None


def test_resolve_host_captures_failure_as_data(monkeypatch):
    def raise_gaierror(host, port):
        raise socket.gaierror("Name or service not known")

    monkeypatch.setattr(network.socket, "getaddrinfo", raise_gaierror)

    result = network.resolve_host("nope.invalid")

    assert result.resolved is False
    assert "Name or service not known" in result.error


def test_resolve_host_restores_default_timeout(monkeypatch):
    monkeypatch.setattr(network.socket, "getaddrinfo", lambda host, port: [("info",)])
    monkeypatch.setattr(network.socket, "getdefaulttimeout", lambda: 42)
    calls = []
    monkeypatch.setattr(network.socket, "setdefaulttimeout", calls.append)

    network.resolve_host("db.example.com", timeout=5)

    # The timeout is set to the probe value (5) and then the previous default (42) is restored last.
    assert calls == [5, 42]


class _FakeSocket:
    def __enter__(self):
        return self

    def __exit__(self, *args):
        return False


def test_tcp_connect_succeeds(monkeypatch):
    monkeypatch.setattr(network.socket, "create_connection", lambda address, timeout=None: _FakeSocket())

    result = network.tcp_connect("db.example.com", 3306)

    assert result.connected is True
    assert result.error is None


def test_tcp_connect_captures_failure_as_data(monkeypatch):
    def refuse(address, timeout=None):
        raise ConnectionRefusedError("Connection refused")

    monkeypatch.setattr(network.socket, "create_connection", refuse)

    result = network.tcp_connect("db.example.com", 3306)

    assert result.connected is False
    assert "Connection refused" in result.error


def test_tcp_connect_captures_timeout_as_data(monkeypatch):
    def time_out(address, timeout=None):
        raise socket.timeout("timed out")

    monkeypatch.setattr(network.socket, "create_connection", time_out)

    result = network.tcp_connect("db.example.com", 3306, timeout=1)

    assert result.connected is False
    assert "timed out" in result.error
