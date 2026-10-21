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

"""Check asserting the critical system services of this node type are active and listening on their ports.

The services are the ones the cookbook enables: munge on every node, slurmctld and the NFS server on the head
node, slurmd on compute nodes, GDRCopy on instances with an NVIDIA GPU, and NVIDIA Fabric Manager on NVSwitch
instances. The ParallelCluster daemons managed
by supervisord are checked by ``ClusterDaemonsAreRunning``.
"""

from typing import List, NamedTuple, Tuple

from pcluster_diag.core.constants import (
    FABRIC_MANAGER_SERVICE,
    GDRCOPY_SERVICE,
    GDRCOPY_SERVICE_UBUNTU,
    MUNGE_SERVICE,
    NFS_SERVER_PORT,
    NFS_SERVER_SERVICE,
    NFS_SERVER_SERVICE_UBUNTU,
    PROC_NET_TCP_PATHS,
    SLURMCTLD_PORTS,
    SLURMCTLD_SERVICE,
    SLURMD_PORT,
    SLURMD_SERVICE,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError, CheckFinding
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import listening_ports, services, software_versions

_ACTIVE_STATE = "active"


class _Service(NamedTuple):
    """A systemd unit that must be active and, when ``ports`` is not empty, listen on one of them."""

    unit: str
    ports: Tuple[int, ...] = ()


class CriticalServicesAreRunning(Check):
    """Verify that the critical system services of this node type are active and listening on their ports."""

    SERVICE_NOT_ACTIVE = CheckError(1, "{} is {}, expected active.")
    PORT_NOT_LISTENING = CheckError(2, "{} is active, but no process listens on TCP {}.")

    PORTS_UNAVAILABLE = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not read the listening TCP ports from {}: the ports of the active services were not checked.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the critical system services (Slurm, munge, NFS, GDRCopy) are active and listening."

    def run(self, context: Context) -> Result:
        """Pass when every expected service is active and listening; fail listing those that are not."""
        expected = self._expected_services(context)
        errors: List[CheckFinding] = []

        ports = listening_ports.listening_tcp_ports() if any(service.ports for service in expected) else set()
        if ports is None:
            errors.append(self.PORTS_UNAVAILABLE.format(", ".join(PROC_NET_TCP_PATHS)))

        for service in expected:
            state = services.systemd_unit_state(service.unit)
            if state != _ACTIVE_STATE:
                errors.append(self.SERVICE_NOT_ACTIVE.format(service.unit, state or "in an unknown state"))
            elif service.ports and ports is not None and ports.isdisjoint(service.ports):
                errors.append(self.PORT_NOT_LISTENING.format(service.unit, _describe_ports(service.ports)))
        return Result.from_findings(self, errors=errors)

    @staticmethod
    def _expected_services(context: Context) -> List[_Service]:
        """Return the services the cookbook enables on this node type."""
        ubuntu = str(((context.dna_json or {}).get("cluster") or {}).get("base_os") or "").startswith("ubuntu")
        expected = [_Service(MUNGE_SERVICE)]
        if context.node_type == NodeType.HEAD:
            expected.append(_Service(SLURMCTLD_SERVICE, SLURMCTLD_PORTS))
            expected.append(_Service(NFS_SERVER_SERVICE_UBUNTU if ubuntu else NFS_SERVER_SERVICE, (NFS_SERVER_PORT,)))
        elif context.node_type == NodeType.COMPUTE:
            expected.append(_Service(SLURMD_SERVICE, (SLURMD_PORT,)))

        # The cookbook starts GDRCopy only on instances with an NVIDIA GPU where it is installed, and NVIDIA Fabric
        # Manager only on the NVSwitch instances where it is installed.
        if software_versions.has_nvidia_gpu():
            gdrcopy = GDRCOPY_SERVICE_UBUNTU if ubuntu else GDRCOPY_SERVICE
            if services.systemd_unit_exists(gdrcopy):
                expected.append(_Service(gdrcopy))
            if software_versions.fabric_manager_expected() and services.systemd_unit_exists(FABRIC_MANAGER_SERVICE):
                expected.append(_Service(FABRIC_MANAGER_SERVICE))
        return expected


def _describe_ports(ports: Tuple[int, ...]) -> str:
    """Return ``port N`` for a single port, or ``ports N-M`` for a range."""
    if len(ports) == 1:
        return "port {}".format(ports[0])
    return "ports {}-{}".format(min(ports), max(ports))
