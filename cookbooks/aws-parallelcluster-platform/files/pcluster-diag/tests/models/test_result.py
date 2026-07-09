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

from pcluster_diag.models.check_error import CheckError
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result, Status
from tests.sample_data import FakeCheck, sample_result

_SAMPLE_CHECK = FakeCheck(identifier="SampleCheck", description="a sample check")


@pytest.mark.parametrize("status", list(Status), ids=lambda status: status.name)
def test_result_status_is_a_valid_status_member(status):
    """A Result's Status is one of PASSED, CHECK_ERROR, FAILURE, SKIPPED_BY_USER, or SKIPPED_NOT_APPLICABLE."""
    result = sample_result(status=status)

    assert result.status in {
        Status.PASSED,
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
def test_skipped_factory_builds_result_with_no_errors(factory, expected_status):
    result = factory(_SAMPLE_CHECK)

    assert result.status is expected_status
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    # A skipped Result never carries errors.
    assert result.errors is None


def test_failure_factory_builds_result_with_errors():
    errors = [CheckError("E1", "boom"), CheckError("E2", "kaboom")]

    result = Result.failure(_SAMPLE_CHECK, errors=errors)

    assert result.status is Status.FAILURE
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    assert result.errors == errors

    # errors default to None when omitted.
    defaults = Result.failure(_SAMPLE_CHECK)
    assert defaults.errors is None
