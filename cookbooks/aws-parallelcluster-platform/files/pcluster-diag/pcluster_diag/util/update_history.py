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

"""Parse the cluster updates the head node ran, and their outcome, from /var/log/chef-client.log.

On every cluster update, cfn-hup runs the cookbook on the head node with the
``aws-parallelcluster-entrypoints::update`` run list. The run logs the change set (``fetch_config``), and when it
fails, the ``UpdateFailureHandler`` logs why. A failed update is rolled back by CloudFormation, which makes cfn-hup run
the update again with the previous metadata: that rollback run logs the same change set, because the change set is
always fetched in its latest version.
"""

import json
import re
from dataclasses import dataclass
from typing import Any, List, Optional

# A /var/log/chef-client.log line: "[2026-10-12T14:02:06+00:00] INFO: message".
_LOG_LINE = re.compile(r"^\[(?P<time>[^\]]+)\] (?P<level>[A-Z]+): (?P<message>.*)$")
# Logged at the start of every run started with --override-runlist.
_RUN_LIST = "Overridden Run List: "
_UPDATE_RUN_LIST = "aws-parallelcluster-entrypoints::update]"
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
    """An update run of the cookbook on the head node.

    Attributes:
        time: When the run started, as logged.
        change_set: The changes of the change set the run logged, or None if the run failed before fetching it.
        failure: Why the run failed, as logged by the UpdateFailureHandler, or None if it did not fail.
        rollback_failure: Whether the UpdateFailureHandler reported the run as a rollback failure.
    """

    time: str
    change_set: Optional[Any] = None
    failure: Optional[str] = None
    rollback_failure: bool = False


def first_log_time(log: List[str]) -> Optional[str]:
    """Return the time of the first line of ``log``, the lines of /var/log/chef-client.log, or None if it has none."""
    for line in log:
        match = _LOG_LINE.match(line)
        if match:
            return match["time"]
    return None


def parse_update_runs(log: List[str]) -> List[UpdateRun]:
    """Return the update runs logged in ``log``, the lines of /var/log/chef-client.log, oldest first."""
    runs: List[UpdateRun] = []
    run: Optional[UpdateRun] = None
    change_set_lines: Optional[List[str]] = None  # the lines of the change set being read

    for line in log:
        match = _LOG_LINE.match(line)
        if not match:
            if change_set_lines is not None:
                change_set_lines.append(line)
            continue
        if change_set_lines is not None:
            run.change_set = _change_set("\n".join(change_set_lines))
            change_set_lines = None

        message = match["message"]
        if message.startswith(_RUN_LIST):
            # Every run starts with its run list: only the update runs are cluster updates.
            run = UpdateRun(time=match["time"]) if _UPDATE_RUN_LIST in message else None
            if run:
                runs.append(run)
        elif run is not None and _read_message(run, message):
            change_set_lines = []

    if change_set_lines is not None:
        run.change_set = _change_set("\n".join(change_set_lines))
    return runs


def _read_message(run: UpdateRun, message: str) -> bool:
    """Record in ``run`` what ``message`` tells about it; return whether the message starts the change set."""
    if message == _CHANGE_SET:
        return True
    if message.startswith(_UPDATE_FAILED) and run.failure is None:
        run.failure = message[len(_UPDATE_FAILED) :]
    elif message.startswith(_ROLLBACK_FAILURE):
        run.rollback_failure = True
    return False


def _change_set(text: str) -> Any:
    """Return the changes of the change set logged as ``text``, or ``text`` itself if it does not start with JSON.

    The change set file has no trailing newline, so the output that cinc writes next follows the JSON: only the JSON
    at the start of ``text`` is decoded.
    """
    try:
        change_set, _ = json.JSONDecoder().raw_decode(text.strip())
        return change_set.get("changeSet", [])
    except (ValueError, AttributeError):
        return text.strip()


def _rollbacks(runs: List[UpdateRun]) -> List[bool]:
    """Return, for each run, whether it rolls back the run before it.

    A failed update is always followed by its rollback run, which repeats the change set of the update: so a run
    repeating the change set of the run before it is a rollback, even when the head node logged no failure. A run
    after a rollback is a new update, even when it retries the same change set.
    """
    rollbacks: List[bool] = []
    for index, run in enumerate(runs):
        previous = runs[index - 1] if index else None
        rollbacks.append(
            previous is not None
            and not rollbacks[-1]
            and (previous.failure is not None or (run.change_set is not None and run.change_set == previous.change_set))
        )
    return rollbacks


def update_outcomes(runs: List[UpdateRun]) -> List[dict]:
    """Return, for each run, its time, outcome, the reason of a logged failure, and its change set.

    The outcome is ``succeeded`` or ``failed`` for an update, and ``rollback succeeded`` or ``rollback failed`` for
    the run that rolls back a failed update.
    """
    rollbacks = _rollbacks(runs)
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
            entry["changeSet"] = run.change_set
        outcomes.append(entry)
    return outcomes
