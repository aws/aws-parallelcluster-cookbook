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
import ssl
import threading
import time

import pytest

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


def test_tls_context_requires_tls_1_2():
    assert network._verified_tls_context().minimum_version == ssl.TLSVersion.TLSv1_2


def test_resolve_host_isolated_succeeds(monkeypatch):
    monkeypatch.setattr(network.socket, "getaddrinfo", lambda host, port: [("family", "socktype")])

    assert network.resolve_host_isolated("ec2.us-east-1.amazonaws.com") == network.DnsResult(resolved=True, error=None)


def test_resolve_host_isolated_captures_failure_as_data(monkeypatch):
    def raise_gaierror(host, port):
        raise socket.gaierror("Name or service not known")

    monkeypatch.setattr(network.socket, "getaddrinfo", raise_gaierror)

    result = network.resolve_host_isolated("nope.invalid")

    assert result.resolved is False
    assert "Name or service not known" in result.error


def test_resolve_host_isolated_times_out_without_waiting_for_the_lookup(monkeypatch):
    release = threading.Event()
    monkeypatch.setattr(network.socket, "getaddrinfo", lambda host, port: release.wait(10))

    started = time.monotonic()
    result = network.resolve_host_isolated("slow.example.com", timeout=0.2)
    elapsed = time.monotonic() - started
    release.set()

    assert result == network.DnsResult(resolved=False, error="no answer within 0.2s")
    assert elapsed < 2


def test_resolve_host_isolated_leaves_the_default_socket_timeout_alone(monkeypatch):
    monkeypatch.setattr(network.socket, "getaddrinfo", lambda host, port: [("info",)])
    monkeypatch.setattr(network.socket, "setdefaulttimeout", lambda value: pytest.fail("global timeout changed"))

    assert network.resolve_host_isolated("ec2.us-east-1.amazonaws.com").resolved is True


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


class _FakeTlsContext:
    """A fake ssl.SSLContext whose wrap_socket either returns a socket or raises the configured error."""

    def __init__(self, wrap_error=None):
        self._wrap_error = wrap_error
        self.server_hostname = None

    def wrap_socket(self, sock, server_hostname=None):
        self.server_hostname = server_hostname
        if self._wrap_error is not None:
            raise self._wrap_error
        return _FakeSocket()


def test_tls_handshake_succeeds(monkeypatch):
    monkeypatch.setattr(network.socket, "create_connection", lambda address, timeout=None: _FakeSocket())
    context = _FakeTlsContext()
    monkeypatch.setattr(network.ssl, "create_default_context", lambda: context)

    result = network.tls_handshake("s3.us-east-1.amazonaws.com")

    assert result.connected is True
    assert result.error is None
    assert result.verification_failed is False
    # SNI / verification name defaults to the host.
    assert context.server_hostname == "s3.us-east-1.amazonaws.com"


def test_tls_handshake_reports_certificate_verification_failure(monkeypatch):
    monkeypatch.setattr(network.socket, "create_connection", lambda address, timeout=None: _FakeSocket())
    verify_error = ssl.SSLCertVerificationError("certificate verify failed: self-signed certificate")
    monkeypatch.setattr(network.ssl, "create_default_context", lambda: _FakeTlsContext(wrap_error=verify_error))

    result = network.tls_handshake("proxy.example.com")

    assert result.connected is False
    assert result.verification_failed is True
    assert "certificate verify failed" in result.error


def test_tls_handshake_captures_transport_failure_as_data(monkeypatch):
    def refuse(address, timeout=None):
        raise ConnectionRefusedError("Connection refused")

    monkeypatch.setattr(network.socket, "create_connection", refuse)
    monkeypatch.setattr(network.ssl, "create_default_context", _FakeTlsContext)

    result = network.tls_handshake("blocked.example.com")

    assert result.connected is False
    # A transport failure is not a certificate-verification failure.
    assert result.verification_failed is False
    assert "Connection refused" in result.error


def test_tls_handshake_uses_explicit_server_hostname(monkeypatch):
    monkeypatch.setattr(network.socket, "create_connection", lambda address, timeout=None: _FakeSocket())
    context = _FakeTlsContext()
    monkeypatch.setattr(network.ssl, "create_default_context", lambda: context)

    network.tls_handshake("10.0.0.5", server_hostname="s3.us-east-1.amazonaws.com")

    assert context.server_hostname == "s3.us-east-1.amazonaws.com"


@pytest.mark.parametrize(
    "address, expected",
    [
        ("http://proxy.local:3128", network.Proxy("http", "proxy.local", 3128)),
        ("https://proxy.local:8443", network.Proxy("https", "proxy.local", 8443)),
        ("proxy.local:3128", network.Proxy("http", "proxy.local", 3128)),
        ("http://proxy.local", network.Proxy("http", "proxy.local", 80)),
        ("https://proxy.local", network.Proxy("https", "proxy.local", 443)),
        ("http://us%40r:p%3Ass@proxy.local:3128", network.Proxy("http", "proxy.local", 3128, "us@r", "p:ss")),
        ("ftp://proxy.local:21", None),
        ("http://:3128", None),
        ("http://proxy.local:port", None),
    ],
)
def test_parse_proxy(address, expected):
    assert network.parse_proxy(address) == expected


def test_proxy_str_hides_the_credentials():
    assert str(network.Proxy("http", "proxy.local", 3128, "user", "secret")) == "http://proxy.local:3128"


def test_connect_request_carries_the_proxy_credentials():
    request = network._connect_request("ec2.us-east-1.amazonaws.com", 443, network.Proxy("http", "p", 1, "user", "pw"))

    assert request == (
        b"CONNECT ec2.us-east-1.amazonaws.com:443 HTTP/1.1\r\n"
        b"Host: ec2.us-east-1.amazonaws.com:443\r\n"
        b"Proxy-Authorization: Basic dXNlcjpwdw==\r\n\r\n"
    )


def test_connect_request_without_credentials():
    request = network._connect_request("ec2.us-east-1.amazonaws.com", 443, network.Proxy("http", "p", 1))

    assert b"Proxy-Authorization" not in request


class _FakeProxy:
    """A local TCP server that answers one CONNECT request with ``answer`` and then closes the connection."""

    def __init__(self, answer: bytes):
        self._server = socket.socket()
        self._server.bind(("127.0.0.1", 0))
        self._server.listen(1)
        self.requests = []
        self._answer = answer
        self._thread = threading.Thread(target=self._serve, daemon=True)
        self._thread.start()

    @property
    def proxy(self):
        return network.Proxy("http", "127.0.0.1", self._server.getsockname()[1])

    def _serve(self):
        connection, _ = self._server.accept()
        with connection:
            request = b""
            while b"\r\n\r\n" not in request:
                data = connection.recv(4096)
                if not data:  # the client closed the connection without a full request
                    return
                request += data
            self.requests.append(request)
            connection.sendall(self._answer)

    def close(self):
        self._thread.join(timeout=5)
        self._server.close()


def test_tls_handshake_via_proxy_reports_a_refused_tunnel():
    fake = _FakeProxy(b"HTTP/1.1 403 Forbidden\r\nContent-Length: 0\r\n\r\n")

    result = network.tls_handshake_via_proxy("ec2.us-east-1.amazonaws.com", 443, fake.proxy)
    fake.close()

    assert result.connected is False
    assert result.tunnel_failed is True
    assert result.error == "the proxy answered 'HTTP/1.1 403 Forbidden'"
    assert fake.requests[0].startswith(b"CONNECT ec2.us-east-1.amazonaws.com:443 HTTP/1.1\r\n")


def test_tls_handshake_via_proxy_reports_a_proxy_closing_before_answering():
    fake = _FakeProxy(b"")

    result = network.tls_handshake_via_proxy("ec2.us-east-1.amazonaws.com", 443, fake.proxy)
    fake.close()

    assert result.connected is False
    assert result.tunnel_failed is True
    assert "closed the connection before answering CONNECT" in result.error


def test_tls_handshake_via_proxy_reports_a_failed_handshake_inside_the_tunnel():
    # The proxy opens the tunnel and then the connection closes before the endpoint answers the TLS handshake.
    fake = _FakeProxy(b"HTTP/1.1 200 Connection established\r\n\r\n")

    result = network.tls_handshake_via_proxy("ec2.us-east-1.amazonaws.com", 443, fake.proxy)
    fake.close()

    assert result.connected is False
    assert result.tunnel_failed is False
    assert result.verification_failed is False


def test_tls_handshake_via_proxy_reports_an_untrusted_certificate(monkeypatch):
    fake = _FakeProxy(b"HTTP/1.1 200 Connection established\r\n\r\n")

    def _untrusted(sock, host, context):
        raise ssl.SSLCertVerificationError("certificate verify failed: self-signed certificate")

    monkeypatch.setattr(network, "_tls_handshake_over", _untrusted)

    result = network.tls_handshake_via_proxy("ec2.us-east-1.amazonaws.com", 443, fake.proxy)
    fake.close()

    assert result.connected is False
    assert result.verification_failed is True
    assert result.tunnel_failed is False


def test_tls_handshake_via_proxy_succeeds_when_the_handshake_completes(monkeypatch):
    fake = _FakeProxy(b"HTTP/1.1 200 Connection established\r\n\r\n")
    monkeypatch.setattr(network, "_tls_handshake_over", lambda sock, host, context: None)

    result = network.tls_handshake_via_proxy("ec2.us-east-1.amazonaws.com", 443, fake.proxy)
    fake.close()

    assert result.connected is True
    assert result.error is None


def test_tls_handshake_via_proxy_reports_an_unreachable_proxy(monkeypatch):
    def refuse(address, timeout=None):
        raise ConnectionRefusedError("Connection refused")

    monkeypatch.setattr(network.socket, "create_connection", refuse)

    result = network.tls_handshake_via_proxy("ec2.us-east-1.amazonaws.com", 443, network.Proxy("http", "p", 3128))

    assert result.connected is False
    assert result.tunnel_failed is True
    assert "Connection refused" in result.error
