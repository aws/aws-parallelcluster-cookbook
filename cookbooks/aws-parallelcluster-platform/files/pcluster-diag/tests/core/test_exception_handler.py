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

"""Unit tests for the ExceptionHandler that translates command exceptions into JSON errors and an exit."""

import json
import logging

import click
import pytest

from pcluster_diag.core.exception_handler import ExceptionHandler
from pcluster_diag.models.exceptions import ContextBuildError, DiagnosticCheckNotPassedError


def _with_traceback(error: Exception) -> Exception:
    """Return ``error`` with a real traceback attached, as it would have when raised."""
    try:
        raise error
    except type(error) as raised:
        return raised


@pytest.mark.parametrize(
    "error, expected_exception, expected_exit_code, expected_error_type, expected_message_substring, expected_logged",
    [
        # Click exceptions are re-raised unchanged (Click renders them); no SystemExit, no JSON, no log.
        (click.ClickException("bad usage"), click.ClickException, None, None, None, False),
        # The Exit signal raised by --help/--version is a Click exception too: re-raised, not reported, not logged.
        (click.exceptions.Exit(0), click.exceptions.Exit, None, None, None, False),
        # Failed checks are already in the report, so only the exit code is emitted: no JSON error, no log.
        (DiagnosticCheckNotPassedError(), SystemExit, 3, None, None, False),
        # A domain error is logged, prints its type/message as JSON, and exits with its own code.
        (ContextBuildError("boom"), SystemExit, 2, "ContextBuildError", "boom", True),
        # A message-less, non-domain exception is logged, exits with the internal-error code, and reports its trace.
        (_with_traceback(RuntimeError()), SystemExit, 1, "RuntimeError", "Traceback (most recent call last)", True),
    ],
    ids=["click-reraised", "help-exit-reraised", "diagnostic-check-not-passed", "domain-error", "message-less-error"],
)
def test_handle(
    capsys,
    caplog,
    error,
    expected_exception,
    expected_exit_code,
    expected_error_type,
    expected_message_substring,
    expected_logged,
):
    with caplog.at_level(logging.ERROR, logger="pcluster_diag.core.exception_handler"):
        with pytest.raises(expected_exception) as exc_info:
            ExceptionHandler().handle(error)

    stdout = capsys.readouterr().out

    # Only the general (JSON-error) branch logs; Click control flow and already-reported check
    # failures are not logged as errors.
    logged = [record for record in caplog.records if record.name == "pcluster_diag.core.exception_handler"]
    assert bool(logged) is expected_logged

    if expected_exit_code is None:
        # Re-raised Click exception: nothing is written to stdout.
        assert stdout == ""
        return

    assert exc_info.value.code == expected_exit_code
    if expected_error_type is None:
        # No JSON error is emitted (the failure is already reported elsewhere).
        assert stdout == ""
    else:
        payload = json.loads(stdout)
        assert payload["errorType"] == expected_error_type
        assert expected_message_substring in payload["errorMessage"]
