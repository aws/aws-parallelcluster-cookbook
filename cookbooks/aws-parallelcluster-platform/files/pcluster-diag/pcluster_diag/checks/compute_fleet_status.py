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

"""Check reporting the compute fleet status and its changes, and whether the fleet is protected or stuck.

The current status comes from the cluster DynamoDB table, where ``pcluster update-compute-fleet`` writes the start
and stop requests. The history of changes comes from the clusterstatusmgtd and clustermgtd logs, so it goes back only
as far as the logs and their rotated copies.

The fleet is stuck when it stays in a transitional status (START_REQUESTED, STOP_REQUESTED, STARTING, STOPPING) longer
than it takes when the daemons work: clusterstatusmgtd did not pick up the request, or did not complete the start or
stop of the compute fleet. The limits are in ``fleet_status.STUCK_AFTER_MINUTES``.
"""

import itertools
from datetime import datetime, timezone
from typing import List

from pcluster_diag.core.constants import CLUSTERMGTD_LOG_PATH, CLUSTERSTATUSMGTD_LOG_PATH
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import fleet_status, log_files
from pcluster_diag.util.serialization import iso_time

# The logs of the daemons that change the compute fleet status, on the head node.
_FLEET_STATUS_LOGS = (CLUSTERSTATUSMGTD_LOG_PATH, CLUSTERMGTD_LOG_PATH)


def _now() -> datetime:
    """Return the current time, in UTC."""
    return datetime.now(tz=timezone.utc)


class ComputeFleetStatusHistory(Check):
    """Report the compute fleet status and its changes, and whether the fleet is protected or stuck."""

    PROTECTED = CheckWarning(
        1, "The compute fleet is PROTECTED since {}: bootstrap failures put partitions {} in INACTIVE."
    )
    STUCK = CheckWarning(2, "The compute fleet is stuck in {} since {} ({} minutes): {}.")

    STATUS_UNREADABLE = CheckError(
        INTERNAL_ERROR_CODE, "Could not read the compute fleet status from the DynamoDB table {}: {}."
    )
    LOGS_UNREADABLE = CheckError(INTERNAL_ERROR_CODE, "Could not read the compute fleet status history: {}.")

    CURRENT_STATUS = CheckInfo(1, "Current compute fleet status: {} (since {}).")
    HISTORY = CheckInfo(2, "{} compute fleet status changes since {}.")
    NO_HISTORY = CheckInfo(3, "No compute fleet status change found in the clusterstatusmgtd and clustermgtd logs.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Report the compute fleet status and its changes, and whether it is protected or stuck."

    def should_run(self, context: Context) -> bool:
        """Run only on the head node: it runs the daemons that manage the compute fleet status."""
        return context.node_type == NodeType.HEAD

    def run(self, context: Context) -> Result:
        """Report the current status, the history of its changes, and whether the fleet is protected or stuck."""
        errors: List[CheckFinding] = []
        warnings: List[CheckFinding] = []
        infos: List[CheckFinding] = []

        cluster = (context.dna_json or {}).get("cluster") or {}
        table_name = cluster.get("ddb_table")
        try:
            status, updated = fleet_status.get_compute_fleet_status(table_name, cluster["region"])
        except Exception as error:  # any failure means the status is unknown
            status = updated = None
            errors.append(self.STATUS_UNREADABLE.format(table_name, error))
        else:
            infos.append(self.CURRENT_STATUS.format(status, iso_time(updated)))

        # Both logs are parsed together: the changes logged by one daemon follow from the lines of the other.
        changes: List[dict] = []
        try:
            lines = itertools.chain.from_iterable(log_files.read_rotated_log(path) for path in _FLEET_STATUS_LOGS)
            status_log = fleet_status.parse_status_changes(lines)
        except OSError as error:
            errors.append(self.LOGS_UNREADABLE.format(error))
        else:
            changes = status_log.changes
            if changes:
                infos.append(self.HISTORY.format(len(changes), status_log.first_time or "unknown"))
            else:
                infos.append(self.NO_HISTORY)

        warning = self._status_warning(status, updated, changes) if status else None
        if warning:
            warnings.append(warning)
        return Result.from_findings(
            self, errors=errors or None, warnings=warnings or None, infos=infos or None, details=changes or None
        )

    def _status_warning(self, status: str, updated, changes: List[dict]):
        """Return the warning for a PROTECTED or stuck fleet, or None."""
        if status == fleet_status.PROTECTED:
            protections = [change for change in changes if change["to"] == fleet_status.PROTECTED]
            partitions = protections[-1].get("partitions") if protections else None
            return self.PROTECTED.format(iso_time(updated), partitions or "(not logged)")
        if status in fleet_status.STUCK_AFTER_MINUTES and updated:
            minutes = int((_now() - updated).total_seconds() // 60)
            if minutes > fleet_status.STUCK_AFTER_MINUTES[status]:
                return self.STUCK.format(status, iso_time(updated), minutes, fleet_status.STUCK_CAUSES[status])
        return None
