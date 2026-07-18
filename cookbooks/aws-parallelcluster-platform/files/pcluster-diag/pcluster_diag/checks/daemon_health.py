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

"""Checks asserting the ParallelCluster management daemons are up and clustermgtd is not wedged.

Two failure modes:

- A management daemon (clustermgtd/clusterstatusmgtd on the head node, computemgtd on compute nodes,
  loginmgtd on login nodes) is not running. ``ClusterDaemonsAreRunning`` catches this.
- clustermgtd is *RUNNING* but blocked on scontrol, or
  filesystem I/O, so its heartbeat stops advancing. Compute nodes then treat the head node as offline
  and can self-terminate. ``ClustermgtdHeartbeatIsHealthy`` catches this stuck state.
"""

from datetime import datetime, timezone

from pcluster_diag.core.constants import (
    CLUSTERMGTD_HEARTBEAT_READ_TIMEOUT_SECONDS,
    CLUSTERMGTD_HEARTBEAT_RELATIVE_PATH,
    CLUSTERMGTD_HEARTBEAT_STALE_THRESHOLD_SECONDS,
    CLUSTERMGTD_HEARTBEAT_TIMESTAMP_FORMAT,
    DEFAULT_SLURM_INSTALL_DIR,
    NODE_TYPE_EXPECTED_DAEMONS,
    SUPERVISORD_RUNNING_STATE,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context, NodeType
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import Result
from pcluster_diag.util.services import get_supervisord_program_state
from pcluster_diag.util.shell import time_command


class ClusterDaemonsAreRunning(Check):
    """Verify that the supervisord-managed ParallelCluster daemons for this node type are RUNNING."""

    DAEMONS_NOT_RUNNING = CheckError(1, "Expected daemon(s) not running on the {}: {}.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the ParallelCluster management daemons for this node type are running."

    def _expected_daemons(self, context: Context):
        """Return the daemons supervisord should keep RUNNING on the current node type."""
        return NODE_TYPE_EXPECTED_DAEMONS.get(context.node_type, ())

    def should_run(self, context: Context) -> bool:
        """Run only on node types that have expected management daemons."""
        return bool(self._expected_daemons(context))

    def run(self, context: Context) -> Result:
        """Pass when every expected daemon is RUNNING; fail listing those that are not."""
        not_running = {}
        for program in self._expected_daemons(context):
            state = get_supervisord_program_state(program)  # raises -> Runner records CHECK_ERROR
            if state != SUPERVISORD_RUNNING_STATE:
                not_running[program] = state

        if not_running:
            details = ", ".join("{} is {}".format(program, state) for program, state in sorted(not_running.items()))
            return Result.failure(self, errors=[self.DAEMONS_NOT_RUNNING.format(context.node_type.value, details)])
        return Result.passed(self)


class ClustermgtdHeartbeatIsHealthy(Check):
    """Detect a stalled clustermgtd by verifying its heartbeat file is present and fresh."""

    HEARTBEAT_READ_TIMED_OUT = CheckError(
        1,
        "Timed out after {:.0f}s reading the clustermgtd heartbeat file {}. The filesystem holding it "
        "may be wedged (e.g. EBS/NFS stuck).",
    )
    HEARTBEAT_UNREADABLE = CheckError(
        2,
        "Could not read the clustermgtd heartbeat file {} (exit code {}). stderr: {}",
    )
    HEARTBEAT_STALE = CheckError(
        3,
        "clustermgtd heartbeat is stale: last updated {:.0f}s ago (threshold {}s). clustermgtd is likely "
        "running but wedged (e.g. blocked on scontrol, directory lookups, or filesystem I/O). Compute "
        "nodes treat the head node as offline once the heartbeat exceeds the threshold and can "
        "self-terminate.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the clustermgtd heartbeat is fresh (clustermgtd is not stalled)."

    def should_run(self, context: Context) -> bool:
        """Run on the head node (where clustermgtd writes) and compute nodes (which depend on it).

        The heartbeat is meaningless on login nodes, so it is skipped there.
        """
        return context.node_type in (NodeType.HEAD, NodeType.COMPUTE)

    def _heartbeat_path(self, context: Context) -> str:
        """Return the clustermgtd heartbeat file path derived from the Slurm install dir."""
        install_dir = (((context.dna_json or {}).get("cluster") or {}).get("slurm") or {}).get(
            "install_dir"
        ) or DEFAULT_SLURM_INSTALL_DIR
        return "{}/{}".format(install_dir.rstrip("/"), CLUSTERMGTD_HEARTBEAT_RELATIVE_PATH)

    def run(self, context: Context) -> Result:
        """Fail when the heartbeat cannot be read or is older than the stale threshold.

        An unparseable heartbeat timestamp means the check cannot complete, so it raises and the Runner
        records it as a CHECK_ERROR.
        """
        path = self._heartbeat_path(context)

        read = time_command(["cat", path], timeout=CLUSTERMGTD_HEARTBEAT_READ_TIMEOUT_SECONDS)
        if read.timed_out:
            return Result.failure(self, errors=[self.HEARTBEAT_READ_TIMED_OUT.format(read.elapsed_seconds, path)])
        if read.returncode != 0:
            return Result.failure(
                self, errors=[self.HEARTBEAT_UNREADABLE.format(path, read.returncode, read.stderr.strip())]
            )

        raw = read.stdout.strip()
        try:
            last_heartbeat = datetime.strptime(raw, CLUSTERMGTD_HEARTBEAT_TIMESTAMP_FORMAT)
        except ValueError as error:
            raise ValueError(
                "Could not parse the clustermgtd heartbeat timestamp {!r}: {}".format(raw, error)
            ) from error

        age_seconds = (datetime.now(timezone.utc) - last_heartbeat).total_seconds()
        if age_seconds > CLUSTERMGTD_HEARTBEAT_STALE_THRESHOLD_SECONDS:
            return Result.failure(
                self, errors=[self.HEARTBEAT_STALE.format(age_seconds, CLUSTERMGTD_HEARTBEAT_STALE_THRESHOLD_SECONDS)]
            )
        return Result.passed(self)
