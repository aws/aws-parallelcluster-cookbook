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

"""Parse the cluster updates the head node ran, and their outcome, from the cinc log.

On every cluster update, cfn-hup runs cinc on the head node with the ``aws-parallelcluster-entrypoints::update`` run
list. The run logs the new cluster config and the change set (``fetch_config``), and when it fails, the
``UpdateFailureHandler`` logs why. A failed update is rolled back by CloudFormation, which makes cfn-hup run the
update again with the previous metadata: that rollback run logs the previous cluster config, but the same change set,
because the change set is always fetched in its latest version.
"""

import json
import re
from dataclasses import dataclass
from typing import Any, List, Optional

# A cinc log line: "[2026-10-12T14:02:06+00:00] INFO: message".
_LOG_LINE = re.compile(r"^\[(?P<time>[^\]]+)\] (?P<level>[A-Z]+): (?P<message>.*)$")
# Logged by cinc at the start of every run started with --override-runlist.
_RUN_LIST = "Overridden Run List: "
_UPDATE_RUN_LIST = "aws-parallelcluster-entrypoints::update]"
_CONFIG = "Cluster config is:"
_CHANGE_SET = "Changeset is:"
_HANDLER = "ErrorHandlers::UpdateFailureHandler: "
_UPDATE_FAILED = _HANDLER + "Update failed on HeadNode due to: "
_ROLLBACK_FAILURE = _HANDLER + "Rollback failure detected"

SUCCEEDED = "succeeded"
FAILED = "failed"
ROLLBACK_SUCCEEDED = "rollback succeeded"
ROLLBACK_FAILED = "rollback failed"


@dataclass
class UpdateRun:
    """An update run of cinc on the head node.

    Attributes:
        time: When the run started, as logged by cinc.
        config: The cluster config the run applied, or None if the run failed before fetching it.
        change_set: The change set the run logged, as text, or None if the run failed before fetching it.
        failure: Why the run failed, as logged by the UpdateFailureHandler, or None if it did not fail.
        rollback_failure: Whether the UpdateFailureHandler reported the run as a rollback failure.
    """

    time: str
    config: Optional[str] = None
    change_set: Optional[str] = None
    failure: Optional[str] = None
    rollback_failure: bool = False


def first_log_time(lines: List[str]) -> Optional[str]:
    """Return the time of the first cinc log line in ``lines``, or None if there is none."""
    for line in lines:
        match = _LOG_LINE.match(line)
        if match:
            return match["time"]
    return None


def parse_update_runs(lines: List[str]) -> List[UpdateRun]:
    """Return the update runs logged in ``lines``, the lines of the cinc log, oldest first."""
    runs: List[UpdateRun] = []
    run: Optional[UpdateRun] = None
    block = None  # the multi-line value being read: "config" or "change_set"
    block_lines: List[str] = []

    for line in lines:
        match = _LOG_LINE.match(line)
        if not match:
            if block:
                block_lines.append(line)
            continue
        if block:
            setattr(run, block, "\n".join(block_lines).strip())
            block, block_lines = None, []

        message = match["message"]
        if message.startswith(_RUN_LIST):
            # Every cinc run starts with its run list: only the update runs are cluster updates.
            run = UpdateRun(time=match["time"]) if _UPDATE_RUN_LIST in message else None
            if run:
                runs.append(run)
        elif run is not None:
            block = _read_message(run, message)

    if block:
        setattr(run, block, "\n".join(block_lines).strip())
    return runs


def _read_message(run: UpdateRun, message: str) -> Optional[str]:
    """Record in ``run`` what ``message`` tells about it; return the multi-line value it starts, if any."""
    if message == _CONFIG:
        return "config"
    if message == _CHANGE_SET:
        return "change_set"
    if message.startswith(_UPDATE_FAILED) and run.failure is None:
        run.failure = message[len(_UPDATE_FAILED) :]
    elif message.startswith(_ROLLBACK_FAILURE):
        run.rollback_failure = True
    return None


def _is_rollback(runs: List[UpdateRun], index: int) -> bool:
    """Return whether ``runs[index]`` rolls back the run before it.

    A failed update is always followed by its rollback run. A rollback run also repeats the change set of the update
    it rolls back, while applying a different config, which shows the update failed even when the head node did not.
    """
    if index == 0:
        return False
    previous, run = runs[index - 1], runs[index]
    if previous.failure:
        return True
    return run.change_set is not None and run.change_set == previous.change_set and run.config != previous.config


def update_outcomes(runs: List[UpdateRun]) -> List[dict]:
    """Return, for each run, its time, outcome, the reason of a logged failure, and its change set.

    The outcome is ``succeeded`` or ``failed`` for an update, and ``rollback succeeded`` or ``rollback failed`` for
    the run that rolls back a failed update.
    """
    rollbacks = [_is_rollback(runs, index) for index in range(len(runs))]
    outcomes = []
    for index, run in enumerate(runs):
        if rollbacks[index]:
            outcome = ROLLBACK_FAILED if run.failure or run.rollback_failure else ROLLBACK_SUCCEEDED
        elif run.failure or (index + 1 < len(runs) and rollbacks[index + 1]):
            outcome = FAILED
        else:
            outcome = SUCCEEDED
        entry: dict = {"time": run.time, "outcome": outcome}
        if run.failure:
            entry["reason"] = run.failure
        if run.change_set is not None:
            entry["changeSet"] = _change_set(run.change_set)
        outcomes.append(entry)
    return outcomes


def _change_set(text: str) -> Any:
    """Return the changes of the change set ``text`` as logged, or the text itself if it is not valid JSON."""
    try:
        return json.loads(text).get("changeSet", [])
    except (ValueError, AttributeError):
        return text
