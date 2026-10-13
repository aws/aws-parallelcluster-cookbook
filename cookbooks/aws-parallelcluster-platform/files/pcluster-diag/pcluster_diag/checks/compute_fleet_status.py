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
and stop requests. The history of changes comes from the clusterstatusmgtd and clustermgtd logs (see
:mod:`pcluster_diag.util.fleet_status`), so it goes back only as far as the logs and their rotated copies.
"""

from datetime import datetime, timezone
from typing import List

from pcluster_diag.core.constants import (
    CLUSTER_EVENTS_API_TIMEOUT_SECONDS,
    CLUSTERMGTD_LOG_PATH,
    CLUSTERSTATUSMGTD_LOG_PATH,
    FLEET_IN_PROGRESS_STUCK_AFTER_MINUTES,
    FLEET_REQUESTED_STUCK_AFTER_MINUTES,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import aws_clients, fleet_status, log_files

# Minutes after which a transitional status means the fleet is stuck.
_STUCK_AFTER_MINUTES = {
    **{status: FLEET_REQUESTED_STUCK_AFTER_MINUTES for status in fleet_status.REQUESTED_STATUSES},
    **{status: FLEET_IN_PROGRESS_STUCK_AFTER_MINUTES for status in fleet_status.IN_PROGRESS_STATUSES},
}


def _iso(time) -> str:
    """Return ``time`` in ISO 8601 to the second."""
    return time.isoformat(timespec="seconds") if time else "unknown"


def _now() -> datetime:
    """Return the current time, in UTC."""
    return datetime.now(tz=timezone.utc)


class ComputeFleetStatusHistory(Check):
    """Report the compute fleet status and its changes, and whether the fleet is protected or stuck."""

    PROTECTED = CheckWarning(
        1, "The compute fleet is PROTECTED since {}: bootstrap failures put partitions {} in INACTIVE."
    )
    STUCK = CheckWarning(2, "The compute fleet is in {} since {} ({} minutes).")

    STATUS_UNREADABLE = CheckError(
        INTERNAL_ERROR_CODE, "Could not read the compute fleet status from the DynamoDB table {}: {}."
    )
    LOGS_UNREADABLE = CheckError(INTERNAL_ERROR_CODE, "Could not read the compute fleet status history: {}.")

    CURRENT_STATUS = CheckInfo(1, "Current compute fleet status: {} (since {}).")
    HISTORY = CheckInfo(
        2, "{} compute fleet status changes since {} (oldest entry in the clusterstatusmgtd and clustermgtd logs)."
    )
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

        changes = []
        try:
            lines = []
            for path in (CLUSTERSTATUSMGTD_LOG_PATH, CLUSTERMGTD_LOG_PATH):
                lines.extend(log_files.read_rotated_log(path)[0])
            changes = fleet_status.parse_status_changes(lines)
            if changes:
                infos.append(
                    self.HISTORY.format(len(changes), fleet_status.first_log_time(lines)).with_details(changes)
                )
            else:
                infos.append(self.NO_HISTORY)
        except OSError as error:
            errors.append(self.LOGS_UNREADABLE.format(error))

        cluster = (context.dna_json or {}).get("cluster") or {}
        table_name = cluster.get("ddb_table")
        try:
            status, updated = fleet_status.get_compute_fleet_status(
                table_name,
                cluster["region"],
                aws_clients.client_config(cluster.get("proxy"), CLUSTER_EVENTS_API_TIMEOUT_SECONDS),
            )
        except Exception as error:  # noqa: BLE001 boto3 raises varied types; any failure means the status is unknown
            errors.append(self.STATUS_UNREADABLE.format(table_name, error))
        else:
            infos.insert(0, self.CURRENT_STATUS.format(status, _iso(updated)))
            warning = self._status_warning(status, updated, changes)
            if warning:
                warnings.append(warning)

        return Result.from_findings(self, errors=errors or None, warnings=warnings or None, infos=infos or None)

    def _status_warning(self, status: str, updated, changes: List[dict]):
        """Return the warning for a PROTECTED or stuck fleet, or None."""
        if status == fleet_status.PROTECTED:
            protections = [change for change in changes if change["to"] == fleet_status.PROTECTED]
            partitions = protections[-1].get("partitions") if protections else None
            return self.PROTECTED.format(_iso(updated), partitions if partitions is not None else "(not logged)")
        if status in _STUCK_AFTER_MINUTES and updated:
            minutes = int((_now() - updated).total_seconds() // 60)
            if minutes > _STUCK_AFTER_MINUTES[status]:
                return self.STUCK.format(status, _iso(updated), minutes)
        return None
