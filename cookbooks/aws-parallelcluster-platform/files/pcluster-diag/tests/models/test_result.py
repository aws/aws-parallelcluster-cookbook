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

from pcluster_diag.models.result import Result, Status
from tests.sample_data import FakeCheck, sample_result

_SAMPLE_CHECK = FakeCheck(identifier="SampleCheck", description="a sample check")


@pytest.mark.parametrize("status", list(Status), ids=lambda status: status.name)
def test_result_status_is_a_valid_status_member(status):
    """A Result's Status is one of PASSED, ERROR, FAILURE, or SKIPPED."""
    result = sample_result(status=status, metadata={"key": "value"})

    assert result.status in {Status.PASSED, Status.ERROR, Status.FAILURE, Status.SKIPPED}


@pytest.mark.parametrize(
    "factory, expected_status",
    [
        (Result.passed, Status.PASSED),
        (Result.error, Status.ERROR),
        (Result.failure, Status.FAILURE),
        (Result.skipped, Status.SKIPPED),
    ],
    ids=["passed", "error", "failure", "skipped"],
)
def test_factory_builds_result_from_check(factory, expected_status):
    message = "a message"
    metadata = {"key": "value"}

    result = factory(_SAMPLE_CHECK, message=message, metadata=metadata)

    assert result.status is expected_status
    assert result.check_id == _SAMPLE_CHECK.identifier
    assert result.check_description == _SAMPLE_CHECK.description
    assert result.message == message
    assert result.metadata == metadata

    # message and metadata default to None when omitted.
    defaults = factory(_SAMPLE_CHECK)
    assert defaults.status is expected_status
    assert defaults.message is None
    assert defaults.metadata is None
