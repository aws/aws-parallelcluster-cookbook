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

"""Readers for the cumulative ENA network counters used to detect congestion."""

import logging
import os
from typing import Dict, Optional

from pcluster_diag.core.constants import (
    ENA_ALLOWANCE_COUNTERS,
    ETHTOOL_PATH,
    FALLBACK_PRIMARY_INTERFACES,
    PROC_NET_ROUTE_PATH,
)
from pcluster_diag.util import shell

logger = logging.getLogger(__name__)


def primary_interface() -> Optional[str]:
    """Return the interface that carries the default route, falling back to the first known primary name.

    ``/proc/net/route`` lists the default route with a ``Destination`` of ``00000000``. When it cannot be
    read, fall back to the conventional primary names (see ``FALLBACK_PRIMARY_INTERFACES``) that exist on
    the node, or None when none of them does.
    """
    try:
        with open(PROC_NET_ROUTE_PATH, encoding="utf-8") as route_file:
            for line in route_file.readlines()[1:]:
                fields = line.split()
                if len(fields) > 1 and fields[1] == "00000000":
                    return fields[0]
    except OSError as error:
        logger.warning("Could not read %s: %s", PROC_NET_ROUTE_PATH, error)

    for interface in FALLBACK_PRIMARY_INTERFACES:
        if os.path.exists(os.path.join("/sys/class/net", interface)):
            return interface
    return None


def ena_allowance_counters(interface: str) -> Optional[Dict[str, int]]:
    """Return the ENA allowance counters of ``interface`` from ``ethtool -S``, or None if ethtool fails.

    Only the counters the driver exposes are returned: older ENA drivers lack some of them (for example
    ``conntrack_allowance_exceeded``), so a missing key means "not reported", not zero.
    """
    try:
        result = shell.run_command([ETHTOOL_PATH, "-S", interface])
    except (OSError, ValueError) as error:
        logger.warning("Could not run ethtool on %s: %s", interface, error)
        return None
    if result.returncode != 0:
        return None
    return parse_ethtool_statistics(result.stdout, ENA_ALLOWANCE_COUNTERS)


def parse_ethtool_statistics(output: str, names) -> Dict[str, int]:
    """Parse the ``name: value`` lines of ``ethtool -S`` output, keeping only the counters in ``names``."""
    counters: Dict[str, int] = {}
    for line in output.splitlines():
        name, separator, value = line.partition(":")
        name = name.strip()
        if separator and name in names:
            try:
                counters[name] = int(value.strip())
            except ValueError:
                logger.warning("Ignoring non-numeric ethtool counter %s=%r", name, value)
    return counters
