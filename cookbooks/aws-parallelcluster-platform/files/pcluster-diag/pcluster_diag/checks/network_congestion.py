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

"""Detect whether the node has been network-throttled, from its ENA allowance counters.

The ENA driver counts the packets that were dropped *or queued* because the instance exceeded one of its
network allowances: bandwidth in/out, packets per second, connection tracking, or link-local traffic (VPC DNS
resolver, IMDS, NTP). These are the counters EC2 points to when an instance is network-throttled, and the OS
logs nothing else when it happens.

The counters are cumulative since the last device reset, which on most nodes means since the instance was
launched. A head node therefore keeps a record of every throttling episode of its lifetime, so the check
reads them once and reports every non-zero counter: it answers "was this node throttled?" after an incident
is over and the load is gone, which is when the tool is usually run. The counters do not record *when* the
throttling happened.

Every probe is read-only.

Source: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-network-performance-ena.html
"""

import logging
from typing import Dict, List

from pcluster_diag.core.constants import ENA_ALLOWANCE_COUNTERS
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import network_counters

logger = logging.getLogger(__name__)

_NO_TIMESTAMP = "The counter does not record when this happened."


class NetworkCongestion(Check):
    """Report every ENA allowance the instance exceeded since its last device reset."""

    # --- Warnings: an ENA allowance was exceeded since the last device reset -------------------
    BANDWIDTH_EXCEEDED = CheckWarning(
        1,
        "{} on {} is {}: since the last device reset, traffic exceeded the instance's {} bandwidth allowance "
        "and packets were queued or dropped. " + _NO_TIMESTAMP,
    )
    PPS_EXCEEDED = CheckWarning(
        2,
        "pps_allowance_exceeded on {} is {}: since the last device reset, the packet rate exceeded the "
        "instance's packets-per-second allowance and packets were queued or dropped. " + _NO_TIMESTAMP,
    )
    CONNTRACK_EXCEEDED = CheckWarning(
        3,
        "conntrack_allowance_exceeded on {} is {}: since the last device reset, the instance's connection "
        "tracking table was full and new connections were dropped. Security group rules that are not fully "
        "open make connections tracked. " + _NO_TIMESTAMP,
    )
    LINKLOCAL_EXCEEDED = CheckWarning(
        4,
        "linklocal_allowance_exceeded on {} is {}: since the last device reset, traffic to link-local services "
        "(the VPC DNS resolver, IMDS, NTP) exceeded its packets-per-second limit and those requests were "
        "dropped. " + _NO_TIMESTAMP,
    )

    # --- Errors: undeterminable (reserved E0 -> CHECK_ERROR, not FAILURE) ----------------------
    COUNTERS_UNAVAILABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not read the ENA allowance counters: {}. Network throttling was not evaluated.",
    )

    # --- Infos --------------------------------------------------------------------------------
    NO_THROTTLING = CheckInfo(1, "No ENA allowance was exceeded on {} since the last device reset.")

    _BANDWIDTH_DIRECTIONS = {"bw_in_allowance_exceeded": "inbound", "bw_out_allowance_exceeded": "outbound"}

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Detect whether the node has been network-throttled, from its ENA allowance counters."

    def run(self, context: Context) -> Result:
        """Read the ENA allowance counters of the primary interface and report every non-zero one."""
        interface = network_counters.primary_interface()
        if not interface:
            return self._unavailable("the primary network interface could not be determined")

        counters = network_counters.ena_allowance_counters(interface)
        if counters is None:
            return self._unavailable("ethtool -S {} failed".format(interface))
        if not any(name in counters for name in ENA_ALLOWANCE_COUNTERS):
            return self._unavailable("the network driver of {} does not report them".format(interface))

        warnings = self._exceeded_allowances(interface, counters)
        infos = None if warnings else [self.NO_THROTTLING.format(interface)]
        return Result.from_findings(self, warnings=warnings, infos=infos)

    def _unavailable(self, reason: str) -> Result:
        """Return a CHECK_ERROR Result (reserved E0) saying why the counters could not be read."""
        return Result.from_findings(self, errors=[self.COUNTERS_UNAVAILABLE.format(reason)])

    def _exceeded_allowances(self, interface: str, counters: Dict[str, int]) -> List[CheckFinding]:
        """Return a warning for every ``*_allowance_exceeded`` counter that is greater than zero."""
        warnings: List[CheckFinding] = []
        for counter in ENA_ALLOWANCE_COUNTERS:
            value = counters.get(counter, 0)
            if value <= 0:
                continue
            if counter in self._BANDWIDTH_DIRECTIONS:
                warnings.append(
                    self.BANDWIDTH_EXCEEDED.format(counter, interface, value, self._BANDWIDTH_DIRECTIONS[counter])
                )
            elif counter == "pps_allowance_exceeded":
                warnings.append(self.PPS_EXCEEDED.format(interface, value))
            elif counter == "conntrack_allowance_exceeded":
                warnings.append(self.CONNTRACK_EXCEEDED.format(interface, value))
            else:
                warnings.append(self.LINKLOCAL_EXCEEDED.format(interface, value))
        return warnings
