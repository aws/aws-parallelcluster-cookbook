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

"""Reader of the TCP ports the node listens on, from /proc/net/tcp and /proc/net/tcp6."""

import logging
from typing import Optional, Set

from pcluster_diag.core.constants import PROC_NET_TCP_PATHS

logger = logging.getLogger(__name__)

# The ``st`` column value of a socket in the LISTEN state.
_TCP_LISTEN_STATE = "0A"


def listening_tcp_ports() -> Optional[Set[int]]:
    """Return the TCP ports with a socket in the LISTEN state, over IPv4 and IPv6, or None if none can be read."""
    ports: Set[int] = set()
    read_any = False
    for path in PROC_NET_TCP_PATHS:
        try:
            with open(path, encoding="utf-8") as tcp_file:
                ports.update(parse_listening_ports(tcp_file.read()))
            read_any = True
        except OSError as error:
            logger.warning("Could not read %s: %s", path, error)
    return ports if read_any else None


def parse_listening_ports(content: str) -> Set[int]:
    """Return the local ports of the LISTEN sockets in a /proc/net/tcp table.

    Each row after the header has ``local_address`` (``<hex ip>:<hex port>``) in the second column and the state
    in the fourth.
    """
    ports = set()
    for line in content.splitlines()[1:]:
        fields = line.split()
        if len(fields) < 4 or fields[3] != _TCP_LISTEN_STATE:
            continue
        _, _, port = fields[1].rpartition(":")
        try:
            ports.add(int(port, 16))
        except ValueError:
            logger.warning("Ignoring unparseable /proc/net/tcp row %r", line)
    return ports
