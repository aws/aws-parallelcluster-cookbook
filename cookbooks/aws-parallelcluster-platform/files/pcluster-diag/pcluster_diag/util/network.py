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

import logging
import socket
from dataclasses import dataclass
from typing import Optional

logger = logging.getLogger(__name__)

DEFAULT_DNS_TIMEOUT_SECONDS = 5
DEFAULT_TCP_TIMEOUT_SECONDS = 5


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


def tcp_connect(host: str, port: int, timeout: int = DEFAULT_TCP_TIMEOUT_SECONDS) -> TcpResult:
    """Attempt a TCP connection to ``host:port`` within ``timeout`` seconds, capturing failures as data."""
    try:
        with socket.create_connection((host, port), timeout=timeout):
            return TcpResult(connected=True, error=None)
    except (socket.timeout, OSError) as error:
        logger.info("TCP connection to %r:%s failed: %s", host, port, error)
        return TcpResult(connected=False, error=str(error))
