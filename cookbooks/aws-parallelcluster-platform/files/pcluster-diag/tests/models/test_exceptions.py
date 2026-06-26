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

"""Unit tests for the domain exceptions and their exit codes."""

import pytest

from pcluster_diag.models.exceptions import (
    ContextBuildError,
    DiagnosticCheckNotPassedError,
    ExitCode,
    InsufficientPrivilegesError,
    PclusterDiagError,
)


def test_exit_code_values_are_stable():
    # Hardcoded on purpose: these numbers are the CLI's contract, so a change here must break the test.
    assert int(ExitCode.INTERNAL_ERROR) == 1
    assert int(ExitCode.CONTEXT_BUILD_ERROR) == 2
    assert int(ExitCode.DIAGNOSTIC_CHECK_FAILURE) == 3
    assert int(ExitCode.INSUFFICIENT_PRIVILEGES) == 4


def test_base_error_defaults_to_internal_error_code():
    error = PclusterDiagError("boom")

    assert error.exit_code == 1
    assert str(error) == "boom"


@pytest.mark.parametrize(
    "factory, expected_code",
    [
        (ContextBuildError, 2),
        (DiagnosticCheckNotPassedError, 3),
        (InsufficientPrivilegesError, 4),
    ],
    ids=["context-build", "diagnostic-check-not-passed", "insufficient-privileges"],
)
def test_domain_errors_carry_expected_exit_code(factory, expected_code):
    error = factory()

    assert isinstance(error, PclusterDiagError)
    assert error.exit_code == expected_code
    # Each carries a non-empty default message.
    assert str(error)
