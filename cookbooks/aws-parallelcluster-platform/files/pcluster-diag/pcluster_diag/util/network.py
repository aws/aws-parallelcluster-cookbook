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

"""Pure socket helpers that turn network failures into data rather than exceptions."""

import base64
import logging
import socket
import ssl
import threading
from dataclasses import dataclass
from typing import Optional
from urllib.parse import unquote, urlparse

logger = logging.getLogger(__name__)

DEFAULT_DNS_TIMEOUT_SECONDS = 5
DEFAULT_TCP_TIMEOUT_SECONDS = 5
DEFAULT_TLS_TIMEOUT_SECONDS = 5


@dataclass
class DnsResult:
    """The outcome of a DNS resolution attempt."""

    resolved: bool
    error: Optional[str]


@dataclass
class TcpResult:
    """The outcome of a TCP connection attempt."""

    connected: bool
    error: Optional[str]


@dataclass
class TlsResult:
    """The outcome of a TLS handshake attempt.

    Attributes:
        connected: Whether a certificate-verified TLS handshake completed.
        error: The failure reason when ``connected`` is False, else None. A verification failure
            (untrusted/expired/mismatched certificate) and a transport failure are both captured here
            as data; the message distinguishes them.
        verification_failed: True specifically when the handshake failed certificate verification
            (as opposed to DNS/TCP/timeout), so callers can tell "reachable but bad cert" from
            "unreachable".
        tunnel_failed: True when the handshake went through a proxy and the proxy did not open the tunnel
            to the endpoint (proxy unreachable, CONNECT refused, or connection lost before the tunnel).
    """

    connected: bool
    error: Optional[str]
    verification_failed: bool = False
    tunnel_failed: bool = False


@dataclass(frozen=True)
class Proxy:
    """An HTTP(S) proxy address, as configured in ``HttpProxyAddress`` (``[scheme://][user:password@]host:port``)."""

    scheme: str
    host: str
    port: int
    username: Optional[str] = None
    password: Optional[str] = None

    def __str__(self) -> str:
        """Return the address without the credentials, safe to show in a finding."""
        return "{}://{}:{}".format(self.scheme, self.host, self.port)


def parse_proxy(address: str) -> Optional[Proxy]:
    """Return the Proxy described by ``address``, or None if it has no host.

    An address without a scheme is an HTTP proxy, and a proxy without a port listens on the scheme's default port.
    """
    parsed = urlparse(address if "://" in address else "http://" + address)
    if parsed.scheme not in ("http", "https") or not parsed.hostname:
        return None
    try:
        port = parsed.port or (443 if parsed.scheme == "https" else 80)
    except ValueError:  # the port is not a number
        return None
    return Proxy(
        scheme=parsed.scheme,
        host=parsed.hostname,
        port=port,
        username=unquote(parsed.username) if parsed.username else None,
        password=unquote(parsed.password) if parsed.password else None,
    )


def resolve_host(host: str, timeout: int = DEFAULT_DNS_TIMEOUT_SECONDS) -> DnsResult:
    """Resolve ``host`` via DNS within ``timeout`` seconds, capturing failures as data."""
    previous_timeout = socket.getdefaulttimeout()
    try:
        socket.setdefaulttimeout(timeout)
        socket.getaddrinfo(host, None)
        return DnsResult(resolved=True, error=None)
    except (socket.gaierror, socket.timeout, OSError) as error:
        logger.info("DNS resolution of %r failed: %s", host, error)
        return DnsResult(resolved=False, error=str(error))
    finally:
        socket.setdefaulttimeout(previous_timeout)


def resolve_host_isolated(host: str, timeout: int = DEFAULT_DNS_TIMEOUT_SECONDS) -> DnsResult:
    """Resolve ``host`` via DNS within ``timeout`` seconds without changing any process-wide setting.

    ``socket.getaddrinfo`` has no timeout of its own, so the lookup runs in a daemon thread that is abandoned
    when it does not answer in time: a stuck lookup neither blocks the caller nor delays the process exit. Safe
    to call from several threads at once.
    """
    outcome = {}

    def _lookup():
        try:
            socket.getaddrinfo(host, None)
            outcome["error"] = None
        except OSError as error:  # socket.gaierror is an OSError
            outcome["error"] = str(error)

    lookup = threading.Thread(target=_lookup, name="pcluster-diag-dns", daemon=True)
    lookup.start()
    lookup.join(timeout)
    if "error" not in outcome:
        logger.info("DNS resolution of %r did not answer within %ss", host, timeout)
        return DnsResult(resolved=False, error="no answer within {}s".format(timeout))
    if outcome["error"]:
        logger.info("DNS resolution of %r failed: %s", host, outcome["error"])
        return DnsResult(resolved=False, error=outcome["error"])
    return DnsResult(resolved=True, error=None)


def tcp_connect(host: str, port: int, timeout: int = DEFAULT_TCP_TIMEOUT_SECONDS) -> TcpResult:
    """Attempt a TCP connection to ``host:port`` within ``timeout`` seconds, capturing failures as data."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return TcpResult(connected=True, error=None)
    except (socket.timeout, OSError) as error:
        logger.info("TCP connection to %r:%s failed: %s", host, port, error)
        return TcpResult(connected=False, error=str(error))


def _verified_tls_context() -> ssl.SSLContext:
    """Return a client TLS context that verifies certificates against the system trust store and requires TLS 1.2+.

    Python 3.10+ already refuses older versions by default; the minimum is set explicitly so it does not depend on
    the interpreter or OpenSSL defaults.
    """
    context = ssl.create_default_context()
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    return context


def tls_handshake(
    host: str,
    port: int = 443,
    timeout: int = DEFAULT_TLS_TIMEOUT_SECONDS,
    server_hostname: Optional[str] = None,
) -> TlsResult:
    """Complete a certificate-verified TLS handshake to ``host:port``, capturing failures as data.

    Uses the system default trust store (``ssl.create_default_context``), so a self-signed or expired
    certificate, or a hostname that does not match the certificate, fails verification -- exactly what
    we want to surface for an AWS service or repository endpoint. ``server_hostname`` sets the SNI /
    verification name; it defaults to ``host`` (pass it when connecting to an IP but verifying a name).

    An ``ssl.SSLCertVerificationError`` (untrusted/expired/mismatched cert) is reported with
    ``verification_failed=True`` so the caller can distinguish "reachable, but the certificate is bad"
    from "could not connect at all" (DNS/TCP/timeout), which are two different remediations.
    """
    context = _verified_tls_context()
    try:
        with socket.create_connection((host, port), timeout=timeout) as sock:
            with context.wrap_socket(sock, server_hostname=server_hostname or host):
                return TlsResult(connected=True, error=None)
    except ssl.SSLCertVerificationError as error:
        logger.info("TLS certificate verification to %r:%s failed: %s", host, port, error)
        return TlsResult(connected=False, error=str(error), verification_failed=True)
    except (ssl.SSLError, socket.timeout, OSError) as error:
        logger.info("TLS handshake to %r:%s failed: %s", host, port, error)
        return TlsResult(connected=False, error=str(error))


_MAX_CONNECT_RESPONSE_BYTES = 64 * 1024


def tls_handshake_via_proxy(
    host: str,
    port: int,
    proxy: Proxy,
    timeout: int = DEFAULT_TLS_TIMEOUT_SECONDS,
) -> TlsResult:
    """Complete a certificate-verified TLS handshake to ``host:port`` through an HTTP CONNECT tunnel.

    This is the path botocore takes when a proxy is configured: connect to the proxy (over TLS for an
    ``https`` proxy), ask it to ``CONNECT host:port``, then run the TLS handshake with the endpoint inside the
    tunnel. The proxy resolves ``host``, so no local DNS lookup is done. A failure before the tunnel is open
    is reported with ``tunnel_failed=True``; after that, failures are reported as by :func:`tls_handshake`.
    """
    context = _verified_tls_context()
    try:
        sock = socket.create_connection((proxy.host, proxy.port), timeout=timeout)
    except (socket.timeout, OSError) as error:
        logger.info("Connection to the proxy %s failed: %s", proxy, error)
        return TlsResult(connected=False, error=str(error), tunnel_failed=True)

    try:
        try:
            # For an https proxy, wrapping detaches the plain socket: only the returned TLS socket needs closing.
            sock = _open_tunnel(sock, host, port, proxy, context)
        except (ssl.SSLError, socket.timeout, OSError) as error:
            logger.info("Tunnel through the proxy %s to %r:%s failed: %s", proxy, host, port, error)
            return TlsResult(connected=False, error=str(error), tunnel_failed=True)
        return _tls_handshake_in_tunnel(sock, host, port, proxy, context)
    finally:
        sock.close()


class _TunnelRefusedError(ConnectionError):
    """The proxy answered CONNECT with a status other than 200."""


def _open_tunnel(sock, host: str, port: int, proxy: Proxy, context: ssl.SSLContext):
    """Ask ``proxy``, connected on ``sock``, for a tunnel to ``host:port`` and return the socket carrying it.

    Raises the ``ssl`` or ``OSError`` exception of a failed connection, or _TunnelRefusedError.
    """
    if proxy.scheme == "https":
        sock = context.wrap_socket(sock, server_hostname=proxy.host)
    sock.sendall(_connect_request(host, port, proxy))
    status_line = _read_connect_status_line(sock)
    if status_line.split(" ")[1:2] != ["200"]:
        raise _TunnelRefusedError("the proxy answered '{}'".format(status_line))
    return sock


def _tls_handshake_in_tunnel(sock, host: str, port: int, proxy: Proxy, context: ssl.SSLContext) -> TlsResult:
    """Run the certificate-verified TLS handshake with ``host`` inside the tunnel open on ``sock``."""
    try:
        _tls_handshake_over(sock, host, context)
        return TlsResult(connected=True, error=None)
    except ssl.SSLCertVerificationError as error:
        logger.info("TLS certificate verification to %r:%s through %s failed: %s", host, port, proxy, error)
        return TlsResult(connected=False, error=str(error), verification_failed=True)
    except (ssl.SSLError, socket.timeout, OSError) as error:
        logger.info("TLS handshake to %r:%s through %s failed: %s", host, port, proxy, error)
        return TlsResult(connected=False, error=str(error))


def _connect_request(host: str, port: int, proxy: Proxy) -> bytes:
    """Return the HTTP CONNECT request asking ``proxy`` for a tunnel to ``host:port``."""
    lines = ["CONNECT {0}:{1} HTTP/1.1".format(host, port), "Host: {0}:{1}".format(host, port)]
    if proxy.username is not None:
        credentials = "{}:{}".format(proxy.username, proxy.password or "").encode("utf-8")
        lines.append("Proxy-Authorization: Basic {}".format(base64.b64encode(credentials).decode("ascii")))
    return ("\r\n".join(lines) + "\r\n\r\n").encode("ascii")


def _read_connect_status_line(sock) -> str:
    """Read the proxy's response to CONNECT up to the end of its headers and return its status line.

    The endpoint sends nothing before the client starts the TLS handshake, so the response ends at the headers.
    """
    response = b""
    while b"\r\n\r\n" not in response:
        data = sock.recv(4096)
        if not data:
            raise ConnectionError("the proxy closed the connection before answering CONNECT")
        response += data
        if len(response) > _MAX_CONNECT_RESPONSE_BYTES:
            raise ConnectionError("the proxy answer to CONNECT is too long")
    return response.split(b"\r\n", 1)[0].decode("latin-1").strip()


def _tls_handshake_over(sock, host: str, context: ssl.SSLContext) -> None:
    """Run a certificate-verified TLS handshake with ``host`` over the already connected ``sock``.

    The handshake runs on memory buffers rather than by wrapping ``sock``, so that it also works inside the TLS
    connection to an ``https`` proxy. Raises the ``ssl`` or ``OSError`` exception of a failed handshake.
    """
    incoming, outgoing = ssl.MemoryBIO(), ssl.MemoryBIO()
    tls = context.wrap_bio(incoming, outgoing, server_hostname=host)
    while True:
        try:
            tls.do_handshake()
            break
        except ssl.SSLWantReadError:
            sock.sendall(outgoing.read())
            data = sock.recv(16384)
            if not data:
                raise ConnectionError("the connection was closed during the TLS handshake")
            incoming.write(data)
    sock.sendall(outgoing.read())
