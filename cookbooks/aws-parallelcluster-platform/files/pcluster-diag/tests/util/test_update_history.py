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

"""Unit tests for the parser of the cluster updates in /var/log/chef-client.log."""

import json

from pcluster_diag.util import update_history

_CHANGE_SET = {
    "changeSet": [
        {
            "parameter": "Scheduling.SlurmQueues[queue].MaxCount",
            "requestedValue": 4,
            "currentValue": 2,
            "updatePolicy": "COMPUTE_FLEET_STOP",
        }
    ]
}


def _line(time, message, level="INFO"):
    return "[{}] {}: {}".format(time, level, message)


def _update_run(time, change_set, failure=None, rollback_failure=False):
    """Return the chef-client.log lines of an update run, as fetch_config and the UpdateFailureHandler log them."""
    lines = [
        _line(time, "Overridden Run List: [recipe[aws-parallelcluster-entrypoints::update]]"),
        _line(time, "Cluster config is:"),
        "Scheduling:",
        "  Scheduler: slurm",
        _line(time, "Changeset is:"),
        *json.dumps(change_set, indent=2).splitlines(),
    ]
    if failure:
        lines.append(_line(time, "ErrorHandlers::UpdateFailureHandler: Update failed on HeadNode due to: " + failure))
    if rollback_failure:
        lines.append(_line(time, "ErrorHandlers::UpdateFailureHandler: Rollback failure detected (marker found)"))
    return lines


def _other_run(time, run_list, failure=None):
    """Return the lines of a run that is not a cluster update, e.g. the compute fleet status update."""
    lines = [_line(time, "Overridden Run List: [recipe[{}]]".format(run_list))]
    if failure:
        lines.append(_line(time, "ErrorHandlers::UpdateFailureHandler: Update failed on HeadNode due to: " + failure))
    return lines


def _outcomes(lines):
    return update_history.update_outcomes(update_history.parse_update_runs(lines).runs)


def test_successful_update():
    (outcome,) = _outcomes(_update_run("2026-10-05T10:20:31+00:00", _CHANGE_SET))

    assert outcome == {
        "time": "2026-10-05T10:20:31+00:00",
        "outcome": "succeeded",
        "changeSet": _CHANGE_SET["changeSet"],
    }


def test_update_failed_on_the_head_node_then_rolled_back():
    lines = _update_run("2026-10-12T14:02:06+00:00", _CHANGE_SET, failure="readiness check failed")
    lines += _update_run("2026-10-12T14:09:13+00:00", _CHANGE_SET)

    failed, rollback = _outcomes(lines)

    assert (failed["outcome"], failed["reason"]) == ("failed", "readiness check failed")
    assert rollback["outcome"] == "rollback succeeded"
    assert "reason" not in rollback


def test_update_failed_after_the_head_node_is_detected_from_its_rollback():
    # The head node logged no failure, but the next run repeats the change set.
    lines = _update_run("2026-10-12T14:02:06+00:00", _CHANGE_SET)
    lines += _update_run("2026-10-12T14:09:13+00:00", _CHANGE_SET)

    failed, rollback = _outcomes(lines)

    assert failed == {"time": "2026-10-12T14:02:06+00:00", "outcome": "failed", "changeSet": _CHANGE_SET["changeSet"]}
    assert rollback["outcome"] == "rollback succeeded"


def test_failed_rollback():
    lines = _update_run("2026-10-12T14:02:06+00:00", _CHANGE_SET, failure="boom")
    lines += _update_run("2026-10-12T14:09:13+00:00", _CHANGE_SET, failure="again", rollback_failure=True)

    _, rollback = _outcomes(lines)

    assert (rollback["outcome"], rollback["reason"]) == ("rollback failed", "again")


def test_update_failing_before_logging_its_change_set():
    lines = [
        _line("2026-10-12T14:02:06+00:00", "Overridden Run List: [recipe[aws-parallelcluster-entrypoints::update]]"),
        _line("2026-10-12T14:02:30+00:00", "ErrorHandlers::UpdateFailureHandler: Update failed on HeadNode due to: x"),
    ]

    (outcome,) = _outcomes(lines)

    assert outcome == {"time": "2026-10-12T14:02:06+00:00", "outcome": "failed", "reason": "x"}


def test_other_runs_are_not_updates_and_their_failures_are_ignored():
    lines = _other_run("2026-10-01T09:00:00+00:00", "aws-parallelcluster-entrypoints::init")
    lines += _update_run("2026-10-05T10:20:31+00:00", _CHANGE_SET)
    lines += _other_run(
        "2026-10-05T10:31:12+00:00", "aws-parallelcluster-entrypoints::update_computefleet_status", failure="fleet"
    )

    (outcome,) = _outcomes(lines)

    assert outcome["outcome"] == "succeeded"


def test_retry_after_a_rollback_is_an_update():
    lines = _update_run("2026-10-12T14:02:06+00:00", _CHANGE_SET, failure="boom")
    lines += _update_run("2026-10-12T14:09:13+00:00", _CHANGE_SET)
    lines += _update_run("2026-10-13T09:00:00+00:00", _CHANGE_SET)

    assert [outcome["outcome"] for outcome in _outcomes(lines)] == ["failed", "rollback succeeded", "succeeded"]


def test_two_consecutive_successful_updates_are_not_a_rollback():
    second_change_set = {"changeSet": [dict(_CHANGE_SET["changeSet"][0], requestedValue=6, currentValue=4)]}
    lines = _update_run("2026-10-05T10:20:31+00:00", _CHANGE_SET)
    lines += _update_run("2026-10-06T10:20:31+00:00", second_change_set)

    assert [outcome["outcome"] for outcome in _outcomes(lines)] == ["succeeded", "succeeded"]


def test_change_set_that_is_not_json_is_kept_as_text():
    lines = [
        _line("2026-10-05T10:20:31+00:00", "Overridden Run List: [recipe[aws-parallelcluster-entrypoints::update]]"),
        _line("2026-10-05T10:20:32+00:00", "Changeset is:"),
        "not json",
    ]

    (outcome,) = _outcomes(lines)

    assert outcome["changeSet"] == "not json"


def test_parse_update_runs_returns_the_time_of_the_first_line():
    lines = iter(["garbage", _line("2026-09-30T08:15:00+00:00", "x"), _line("2026-09-30T09:00:00+00:00", "y")])

    assert update_history.parse_update_runs(lines).first_time == "2026-09-30T08:15:00+00:00"
    assert update_history.parse_update_runs([]).first_time is None
