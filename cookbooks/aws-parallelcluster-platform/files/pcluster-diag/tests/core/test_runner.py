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

"""Unit tests for the Runner execution engine."""

import logging

from pcluster_diag.core.runner import Runner
from pcluster_diag.models.result import Status
from tests.sample_data import FAKE_CHECK_RAISE_MESSAGE, FakeCheck, sample_context


def test_executes_in_given_order():
    checks = [FakeCheck("A"), FakeCheck("B"), FakeCheck("C")]

    results = Runner().execute(sample_context(), checks)

    assert [r.check_id for r in results] == ["A", "B", "C"]


def test_failure_does_not_stop_remaining_checks():
    a = FakeCheck("A", status=Status.FAILURE)
    b = FakeCheck("B", status=Status.PASSED)

    results = Runner().execute(sample_context(), [a, b])

    assert results[0].status == Status.FAILURE
    assert results[1].status == Status.PASSED
    assert b.ran is True


def test_unhandled_exception_becomes_error_with_stack_trace():
    a = FakeCheck("A", raises=True)
    b = FakeCheck("B")

    results = Runner().execute(sample_context(), [a, b])

    assert results[0].status == Status.ERROR
    assert "Traceback" in results[0].message
    assert FAKE_CHECK_RAISE_MESSAGE in results[0].message
    # Isolation: the next Check still ran.
    assert results[1].status == Status.PASSED


def test_not_approved_check_yields_skipped_by_user():
    a = FakeCheck("A")

    results = Runner().execute(sample_context(), [a], check_not_approved=[a])

    assert results[0].status == Status.SKIPPED
    assert results[0].message == "Skipped by the user"
    # A not-approved Check is never executed.
    assert a.ran is False


def test_check_to_run_is_executed_regardless_of_should_run():
    # Applicability is decided before execute(); the Runner runs every check_to_run unconditionally.
    a = FakeCheck("A", applicable=False)

    results = Runner().execute(sample_context(), [a])

    assert results[0].status == Status.PASSED
    # The check's run body is invoked even though should_run would return False.
    assert a.ran is True


def test_emits_outcome_log_line_per_check(caplog):
    a = FakeCheck("A", status=Status.PASSED)
    b = FakeCheck("B", status=Status.FAILURE)

    with caplog.at_level(logging.INFO, logger="pcluster_diag.core.runner"):
        Runner().execute(sample_context(), [a, b])

    messages = [record.getMessage() for record in caplog.records]
    assert "A: PASSED" in messages
    assert "B: FAILURE" in messages
    # FAILURE outcomes are logged at error level; PASSED at info level.
    levels = {record.getMessage(): record.levelno for record in caplog.records}
    assert levels["A: PASSED"] == logging.INFO
    assert levels["B: FAILURE"] == logging.ERROR


def test_results_follow_registration_order_across_dispositions():
    # Checks are emitted in the order given (registration order), regardless of disposition: an
    # executed Check, a non-applicable one, another executed Check, and a user-declined one.
    run1 = FakeCheck("Run1")
    skip = FakeCheck("Skip", applicable=False)
    run2 = FakeCheck("Run2")
    declined = FakeCheck("Declined")

    results = Runner().execute(
        sample_context(),
        [run1, skip, run2, declined],
        check_not_applicable=[skip],
        check_not_approved=[declined],
    )

    assert [(r.check_id, r.status) for r in results] == [
        ("Run1", Status.PASSED),
        ("Skip", Status.SKIPPED),
        ("Run2", Status.PASSED),
        ("Declined", Status.SKIPPED),
    ]
    # Skipped / declined Checks carry their user-facing messages and never execute.
    skip_result = next(r for r in results if r.check_id == "Skip")
    declined_result = next(r for r in results if r.check_id == "Declined")
    assert skip_result.message == "Check is not applicable to the current context."
    assert declined_result.message == "Skipped by the user"
    assert skip.ran is False
    assert declined.ran is False
