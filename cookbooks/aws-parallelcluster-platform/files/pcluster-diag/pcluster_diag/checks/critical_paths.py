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

When a critical file loses its expected owner or mode, the daemon that relies on it fails in ways that
are hard to trace back to a permissions problem. For example, a ``computefleet-status.json`` that is no
longer writable by ``pcluster-admin`` makes ``clusterstatusmgtd`` raise ``[Errno 13] Permission denied``
and the compute fleet gets stuck mid-transition (e.g. never leaving STOPPING).
"""

from typing import List, Optional

from pcluster_diag.core.constants import (
    CLUSTER_ADMIN_GROUP,
    CLUSTER_ADMIN_USER,
    COMPUTEFLEET_STATUS_PATH,
    MUNGE_KEY_PATH,
    MUNGE_USER,
    SLURM_STATE_SAVE_PATH,
    SLURM_USER,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.expected_path_permissions import ExpectedPathPermissions
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import Result
from pcluster_diag.util import path_permissions

# The critical paths ParallelCluster provisions, with the ownership/mode set by the cookbook. Add an
# entry here whenever an investigation traces a failure to a mis-permissioned path.
CRITICAL_PATHS: List[ExpectedPathPermissions] = [
    # clusterstatusmgtd runs as pcluster-admin and writes the compute-fleet status here; if it loses
    # write access, fleet status transitions fail with EACCES.
    ExpectedPathPermissions(
        path=COMPUTEFLEET_STATUS_PATH,
        owner=CLUSTER_ADMIN_USER,
        group=CLUSTER_ADMIN_GROUP,
        mode="0755",
        node_types=(NodeType.HEAD,),
    ),
    # Munge underpins Slurm authentication; munged refuses to start if its key is not private to the
    # munge user, breaking Slurm cluster-wide. Present wherever munge runs (head and compute).
    ExpectedPathPermissions(
        path=MUNGE_KEY_PATH,
        owner=MUNGE_USER,
        group=MUNGE_USER,
        mode="0600",
        node_types=(NodeType.HEAD, NodeType.COMPUTE),
    ),
    # Slurm's StateSaveLocation; slurmctld cannot start if it is not owned by and private to the slurm user.
    ExpectedPathPermissions(
        path=SLURM_STATE_SAVE_PATH,
        owner=SLURM_USER,
        group=SLURM_USER,
        mode="0700",
        node_types=(NodeType.HEAD,),
    ),
]


class CriticalPathsHaveExpectedPermissions(Check):
    """Verify ParallelCluster's critical files exist with their expected owner, group, and mode."""

    MISSING_PATH = CheckError(1, "'{}' is missing.")
    WRONG_OWNERSHIP = CheckError(2, "'{}' is owned by {}:{} but should be {}:{}.")
    WRONG_MODE = CheckError(3, "'{}' has mode {} but should be {}.")

    def __init__(self, critical_paths: Optional[List[ExpectedPathPermissions]] = None) -> None:
        """Create the Check, optionally overriding the inspected critical paths (used by tests)."""
        self._critical_paths = CRITICAL_PATHS if critical_paths is None else critical_paths

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that ParallelCluster critical files have their expected owner, group, and permissions."

    def run(self, context: Context) -> Result:
        """Pass when every applicable critical path matches its expected owner/group/mode; fail otherwise."""
        errors = []
        for critical in self._applicable(context):
            errors.extend(self._inspect(critical))

        if errors:
            return Result.failure(self, errors=errors)
        return Result.passed(self)

    def _applicable(self, context: Context) -> List[ExpectedPathPermissions]:
        """Return the critical paths expected on the current node type."""
        return [critical for critical in self._critical_paths if context.node_type in critical.node_types]

    def _inspect(self, critical: ExpectedPathPermissions) -> List[CheckError]:
        """Return the CheckErrors for ``critical``: empty when it exists with the expected ownership and mode."""
        try:
            observed = path_permissions.stat_path(critical.path)
        except FileNotFoundError:
            return [self.MISSING_PATH.format(critical.path)]

        errors = []
        if observed.owner != critical.owner or observed.group != critical.group:
            errors.append(
                self.WRONG_OWNERSHIP.format(
                    critical.path, observed.owner, observed.group, critical.owner, critical.group
                )
            )
        if observed.mode != critical.mode:
            errors.append(self.WRONG_MODE.format(critical.path, observed.mode, critical.mode))
        return errors
