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

"""Check asserting ParallelCluster's critical files have their expected ownership and permissions.

When a critical file loses its expected owner or permissions, the daemon that relies on it fails in
ways that are hard to trace back to a permissions problem. For example, a ``computefleet-status.json``
that is no longer writable by ``pcluster-admin`` makes ``clusterstatusmgtd`` raise ``[Errno 13]
Permission denied`` and the compute fleet gets stuck mid-transition (e.g. never leaving STOPPING).

Each expectation below encodes what the consuming daemon actually enforces, not the mode the cookbook
currently sets: several modes are usually acceptable, and a path can break both by being loosened
(insecure) and by being tightened (the daemon loses an access it needs).
"""

from typing import List, Optional

from pcluster_diag.core.constants import (
    CLUSTER_ADMIN_GROUP,
    CLUSTER_ADMIN_USER,
    COMPUTEFLEET_STATUS_PATH,
    GROUP_OTHER_READ_WRITE,
    GROUP_OTHER_WRITE,
    MUNGE_KEY_PATH,
    MUNGE_USER,
    OWNER_READ,
    OWNER_TRAVERSE,
    OWNER_WRITE,
    SLURM_STATE_SAVE_PATH,
    SLURM_USER,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.expected_path_permissions import ExpectedPathPermissions
from pcluster_diag.models.finding import CheckError, CheckWarning
from pcluster_diag.models.result import Result
from pcluster_diag.util import path_permissions
from pcluster_diag.util.path_permissions import describe_bits

# The critical paths ParallelCluster provisions. Add an entry here whenever an investigation traces a
# failure to a mis-permissioned path.
CRITICAL_PATHS: List[ExpectedPathPermissions] = [
    # clusterstatusmgtd (as pcluster-admin) opens this for writing; without owner write it raises
    # EACCES and the fleet stalls mid-transition. A wider mode does not stop it, so it is an advisory.
    ExpectedPathPermissions(
        path=COMPUTEFLEET_STATUS_PATH,
        owner=CLUSTER_ADMIN_USER,
        group=CLUSTER_ADMIN_GROUP,
        node_types=(NodeType.HEAD,),
        required_bits=OWNER_WRITE,
        forbidden_bits=GROUP_OTHER_WRITE,
    ),
    # Munge underpins Slurm authentication cluster-wide. munged refuses to start when the key is
    # group/other readable or writable -- the one path where a wider mode is a failure, not an advisory
    # -- and, running unprivileged, it also cannot start when it cannot read the key itself. The
    # cookbook installs the key identically on head, compute and login nodes.
    ExpectedPathPermissions(
        path=MUNGE_KEY_PATH,
        owner=MUNGE_USER,
        group=MUNGE_USER,
        node_types=(NodeType.HEAD, NodeType.COMPUTE, NodeType.LOGIN),
        required_bits=OWNER_READ,
        forbidden_bits=GROUP_OTHER_READ_WRITE,
        forbidden_bits_break_daemon=True,
    ),
    # Slurm's StateSaveLocation. slurmctld drops to SlurmUser and then requires read, write and
    # traverse here, exiting fatal otherwise -- so tightening to 0600, which drops traverse, breaks it
    # just as surely as loosening. It starts fine on 0777, so a wider mode is only an advisory.
    ExpectedPathPermissions(
        path=SLURM_STATE_SAVE_PATH,
        owner=SLURM_USER,
        group=SLURM_USER,
        node_types=(NodeType.HEAD,),
        required_bits=OWNER_READ | OWNER_WRITE | OWNER_TRAVERSE,
        forbidden_bits=GROUP_OTHER_WRITE,
    ),
]


class CriticalPathsHaveExpectedPermissions(Check):
    """Verify ParallelCluster's critical files exist with their expected ownership and permissions."""

    MISSING_PATH = CheckError(1, "'{}' is missing.")
    WRONG_OWNERSHIP = CheckError(2, "'{}' is owned by {}:{} but should be {}:{}.")
    MISSING_PERMISSIONS = CheckError(3, "'{}' has mode {}, which does not grant {}.")
    INSECURE_PERMISSIONS = CheckError(4, "'{}' has mode {}, which must not grant {}.")
    # Reported instead of INSECURE_PERMISSIONS when the daemon keeps running, so it does not fail the run.
    OVER_PERMISSIVE = CheckWarning(1, "'{}' has mode {}, which should not grant {}.")

    def __init__(self, critical_paths: Optional[List[ExpectedPathPermissions]] = None) -> None:
        """Create the Check, optionally overriding the inspected critical paths (used by tests)."""
        self._critical_paths = CRITICAL_PATHS if critical_paths is None else critical_paths

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that ParallelCluster critical files have their expected owner, group, and permissions."

    def run(self, context: Context) -> Result:
        """Pass when every applicable critical path has its expected ownership and permissions."""
        errors: List[CheckError] = []
        warnings: List[CheckWarning] = []
        for critical in self._applicable(context):
            self._inspect(critical, errors, warnings)

        return Result.from_findings(self, errors=errors, warnings=warnings)

    def _applicable(self, context: Context) -> List[ExpectedPathPermissions]:
        """Return the critical paths expected on the current node type."""
        return [critical for critical in self._critical_paths if context.node_type in critical.node_types]

    def _inspect(
        self, critical: ExpectedPathPermissions, errors: List[CheckError], warnings: List[CheckWarning]
    ) -> None:
        """Collect the findings for ``critical`` into ``errors``/``warnings``."""
        try:
            observed = path_permissions.stat_path(critical.path)
        except FileNotFoundError:
            errors.append(self.MISSING_PATH.format(critical.path))
            return

        if observed.owner != critical.owner or observed.group != critical.group:
            errors.append(
                self.WRONG_OWNERSHIP.format(
                    critical.path, observed.owner, observed.group, critical.owner, critical.group
                )
            )
        self._inspect_mode(critical, observed.mode, errors, warnings)

    def _inspect_mode(
        self,
        critical: ExpectedPathPermissions,
        mode: str,
        errors: List[CheckError],
        warnings: List[CheckWarning],
    ) -> None:
        """Collect the findings for ``mode`` against ``critical``'s permission expectation."""
        missing = critical.missing_bits(mode)
        if missing:
            errors.append(self.MISSING_PERMISSIONS.format(critical.path, mode, describe_bits(missing)))

        offending = critical.offending_bits(mode)
        if offending:
            granted = describe_bits(offending)
            if critical.forbidden_bits_break_daemon:
                errors.append(self.INSECURE_PERMISSIONS.format(critical.path, mode, granted))
            else:
                warnings.append(self.OVER_PERMISSIVE.format(critical.path, mode, granted))
