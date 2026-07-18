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

"""Unit tests for the Result model and its factory methods."""

import pytest

from pcluster_diag.models.finding import CheckError, CheckInfo, CheckWarning
from pcluster_diag.models.result import FAILED_STATUSES, INTERNAL_ERROR_CODE, Result, Status
from tests.sample_data import FakeCheck, sample_result

_SAMPLE_CHECK = FakeCheck(identifier="SampleCheck", description="a sample check")


@pytest.mark.parametrize("status", list(Status), ids=lambda status: status.name)
def test_result_status_is_a_valid_status_member(status):
    """A Result's Status is one of PASSED, WARNING, CHECK_ERROR, FAILURE, SKIPPED_BY_USER, or SKIPPED_NOT_APPLICABLE."""
    result = sample_result(status=status)

    assert result.status in {
        Status.PASSED,
        Status.WARNING,
        Status.CHECK_ERROR,
        Status.FAILURE,
        Status.SKIPPED_BY_USER,
        Status.SKIPPED_NOT_APPLICABLE,
    }


def test_passed_factory_builds_result_from_check():
    result = Result.passed(_SAMPLE_CHECK)

    assert result.status is Status.PASSED
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    # A PASSED Result carries no errors.
    assert result.errors is None


def test_error_factory_builds_check_error_result_from_exception():
    exception = ValueError("something went wrong")

    result = Result.error(_SAMPLE_CHECK, exception)

    assert result.status is Status.CHECK_ERROR
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    # A CHECK_ERROR carries a single E0 error coded "{exceptionName}: {exceptionMessage}".
    assert result.errors == [CheckError(INTERNAL_ERROR_CODE, "ValueError: something went wrong")]


@pytest.mark.parametrize(
    "factory, expected_status",
    [
        (Result.skipped_by_user, Status.SKIPPED_BY_USER),
        (Result.skipped_not_applicable, Status.SKIPPED_NOT_APPLICABLE),
    ],
    ids=["skipped-by-user", "skipped-not-applicable"],
)
def test_skipped_factory_defaults_to_no_infos(factory, expected_status):
    result = factory(_SAMPLE_CHECK)

    assert result.status is expected_status
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    # A skipped Result carries no findings unless the caller supplies a reason.
    assert result.infos is None
    assert result.errors is None


@pytest.mark.parametrize(
    "factory, expected_status",
    [
        (Result.skipped_by_user, Status.SKIPPED_BY_USER),
        (Result.skipped_not_applicable, Status.SKIPPED_NOT_APPLICABLE),
    ],
    ids=["skipped-by-user", "skipped-not-applicable"],
)
def test_skipped_factory_carries_reason_infos(factory, expected_status):
    reasons = [CheckInfo(1, "tool unavailable")]

    result = factory(_SAMPLE_CHECK, infos=reasons)

    assert result.status is expected_status
    assert result.infos == reasons
    # A skip reason is informational, not an error.
    assert result.errors is None


def test_failure_factory_builds_result_with_errors():
    errors = [CheckError(1, "boom"), CheckError(2, "kaboom")]

    result = Result.failure(_SAMPLE_CHECK, errors=errors)

    assert result.status is Status.FAILURE
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    assert result.errors == errors

    # errors and warnings default to None when omitted.
    defaults = Result.failure(_SAMPLE_CHECK)
    assert defaults.errors is None
    assert defaults.warnings is None


def test_failure_factory_can_carry_warnings():
    errors = [CheckError(1, "boom")]
    warnings = [CheckWarning(1, "heads up")]

    result = Result.failure(_SAMPLE_CHECK, errors=errors, warnings=warnings)

    assert result.status is Status.FAILURE
    assert result.errors == errors
    assert result.warnings == warnings


def test_warning_factory_builds_result_with_warnings():
    warnings = [CheckWarning(1, "heads up"), CheckWarning(2, "also this")]

    result = Result.warning(_SAMPLE_CHECK, warnings=warnings)

    assert result.status is Status.WARNING
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    # A WARNING Result carries warnings but no errors.
    assert result.warnings == warnings
    assert result.errors is None

    # warnings default to None when omitted.
    assert Result.warning(_SAMPLE_CHECK).warnings is None


def test_warning_status_is_not_a_failed_status():
    # A WARNING is advisory: it does not make the run unsuccessful.
    assert Status.WARNING not in FAILED_STATUSES
