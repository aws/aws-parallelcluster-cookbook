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

"""Check reporting the cluster updates the head node applied, with their change sets and outcomes.

The history comes from the cinc log of the head node (see :mod:`pcluster_diag.util.update_history`), so it goes back
only as far as the log and its rotated copy. The status of the cluster stack tells the outcome of the latest update
overall, including when it failed before reaching the head node, e.g. in the queues stack.
"""

import logging
from typing import List, Optional

from pcluster_diag.core.constants import CHEF_CLIENT_LOG_PATH, CLUSTER_EVENTS_API_TIMEOUT_SECONDS
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo, CheckWarning
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import aws_clients, cfn, log_files, update_history

logger = logging.getLogger(__name__)

# Stack statuses that mean the latest update did not complete.
_INCOMPLETE_UPDATE_STATUSES = frozenset(
    {
        "UPDATE_FAILED",
        "UPDATE_ROLLBACK_IN_PROGRESS",
        "UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS",
        "UPDATE_ROLLBACK_COMPLETE",
        "UPDATE_ROLLBACK_FAILED",
    }
)


def _iso(time) -> str:
    """Return ``time`` in ISO 8601 to the second, like the cinc log times."""
    return time.isoformat(timespec="seconds") if time else "unknown"


class ClusterUpdateHistory(Check):
    """Report the cluster updates applied on the head node, their change sets and outcomes."""

    LATEST_UPDATE_INCOMPLETE = CheckWarning(
        1, "The latest cluster update did not complete: stack status {} (last updated {})."
    )

    LOG_UNREADABLE = CheckError(INTERNAL_ERROR_CODE, "Could not read the cluster update history from {}: {}.")

    HISTORY = CheckInfo(1, "{} cluster update runs since {} (oldest entry in {}).")
    # The second placeholder is " since <time of the oldest log entry>", or empty for an empty log.
    NO_HISTORY = CheckInfo(2, "No cluster update found in {}{}.")
    STACK_STATUS = CheckInfo(3, "Current stack status: {} (last updated {}).")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Report the cluster updates applied on the head node, their changesets and outcomes."

    def should_run(self, context: Context) -> bool:
        """Run only on the head node: it is the only node that runs the cluster update."""
        return context.node_type == NodeType.HEAD

    def run(self, context: Context) -> Result:
        """Report the update history from the cinc log, and the status of the cluster stack."""
        try:
            lines, files = log_files.read_rotated_log(CHEF_CLIENT_LOG_PATH)
        except OSError as error:
            return Result.from_findings(self, errors=[self.LOG_UNREADABLE.format(CHEF_CLIENT_LOG_PATH, error)])
        if not files:
            return Result.from_findings(
                self, errors=[self.LOG_UNREADABLE.format(CHEF_CLIENT_LOG_PATH, "the file does not exist")]
            )

        since = update_history.first_log_time(lines)
        runs = update_history.update_outcomes(update_history.parse_update_runs(lines))
        infos: List[CheckFinding] = []
        if runs:
            infos.append(self.HISTORY.format(len(runs), since, files[0]).with_details(runs))
        else:
            infos.append(self.NO_HISTORY.format(" and ".join(files), " since {}".format(since) if since else ""))

        warnings: List[CheckFinding] = []
        stack_status = self._stack_status(context)
        if stack_status:
            status, updated = stack_status[0], _iso(stack_status[1])
            infos.append(self.STACK_STATUS.format(status, updated))
            if status in _INCOMPLETE_UPDATE_STATUSES:
                warnings.append(self.LATEST_UPDATE_INCOMPLETE.format(status, updated))
        return Result.from_findings(self, warnings=warnings or None, infos=infos)

    @staticmethod
    def _stack_status(context: Context) -> Optional[tuple]:
        """Return the status of the cluster stack and its last update time, or None if they cannot be read."""
        cluster = (context.dna_json or {}).get("cluster") or {}
        try:
            return cfn.get_stack_status(
                cluster["stack_name"],
                cluster["region"],
                aws_clients.client_config(cluster.get("proxy"), CLUSTER_EVENTS_API_TIMEOUT_SECONDS),
            )
        except Exception as error:  # noqa: BLE001 the stack status is optional: any failure only omits it
            logger.info("Could not read the status of the cluster stack: %s", error)
            return None
