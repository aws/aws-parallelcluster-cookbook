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

"""Result model carrying the structured outcome of a Check execution."""

from dataclasses import dataclass
from enum import Enum
from typing import List, Optional

from pcluster_diag.models.finding import CheckError, CheckInfo, CheckWarning


class Status(Enum):
    """The status of a Check execution."""

    PASSED = "PASSED"  # condition satisfied
    WARNING = "WARNING"  # condition satisfied, but with non-fatal warnings (still successful)
    CHECK_ERROR = "CHECK_ERROR"  # check raised / could not complete
    FAILURE = "FAILURE"  # check completed; condition not satisfied
    SKIPPED_BY_USER = "SKIPPED_BY_USER"  # user did not approve its execution
    SKIPPED_NOT_APPLICABLE = "SKIPPED_NOT_APPLICABLE"  # does not apply to the context


# Statuses that make the run unsuccessful: any of these in the results yields a non-zero exit code.
# WARNING is deliberately excluded: a check carrying only warnings is considered successful.
FAILED_STATUSES = (Status.FAILURE, Status.CHECK_ERROR)

# The error code carried by a CHECK_ERROR Result (an exception prevented the Check's completion).
INTERNAL_ERROR_CODE = 0


def _is_unexpected_error(finding) -> bool:
    """Return whether ``finding`` is an unexpected-error finding (carries the reserved E0 code)."""
    return finding.code == "E{}".format(INTERNAL_ERROR_CODE)


def _dedupe(findings):
    """Return ``findings`` with exact duplicates (same code and message) removed, preserving order."""
    seen = set()
    unique = []
    for finding in findings:
        key = (finding.code, finding.message)
        if key not in seen:
            seen.add(key)
            unique.append(finding)
    return unique


@dataclass
class Result:
    """The outcome of executing a Check.

    Attributes:
        check_id: The check identifier (the Check class simple name).
        check_description: The Check's human-readable description.
        status: The Status of the execution (PASSED, WARNING, CHECK_ERROR, FAILURE, SKIPPED_BY_USER,
            or SKIPPED_NOT_APPLICABLE).
        errors: The set of failure modes for a FAILURE or CHECK_ERROR Result, each a CheckError
            (code + message); None for any other status.
        warnings: The set of non-fatal warnings raised by the Check, each a CheckWarning (code +
            message); present on a WARNING Result and optionally on a FAILURE Result; None otherwise.
        infos: Informational notes, each a CheckInfo (code + message); used to explain why a SKIPPED_*
            Result was skipped; None otherwise.
    """

    check_id: str
    check_description: str
    status: Status
    errors: Optional[List[CheckError]] = None
    warnings: Optional[List[CheckWarning]] = None
    infos: Optional[List[CheckInfo]] = None

    @staticmethod
    def passed(check) -> "Result":
        """Build a PASSED Result for ``check`` (its condition was satisfied)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.PASSED,
        )

    @staticmethod
    def from_findings(check, errors=None, warnings=None, infos=None) -> "Result":
        """Build a Result for ``check`` whose status is derived from its findings by severity precedence.

        The severity precedence is FAILURE > CHECK_ERROR > WARNING > PASSED:

        - FAILURE when any *expected* error is present (a real problem the check detected);
        - else CHECK_ERROR when the only errors are *unexpected* ones (code E0, from an isolated probe
          crash) -- the check could not fully complete, but no real problem was confirmed;
        - else WARNING when any warning is present;
        - else PASSED.
        """
        errors = _dedupe(errors or [])
        warnings = _dedupe(warnings or [])
        infos = _dedupe(infos or [])
        if any(not _is_unexpected_error(error) for error in errors):
            status = Status.FAILURE
        elif errors:
            status = Status.CHECK_ERROR
        elif warnings:
            status = Status.WARNING
        else:
            status = Status.PASSED
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=status,
            errors=errors or None,
            warnings=warnings or None,
            infos=infos or None,
        )

    @staticmethod
    def error(check, exception: Exception) -> "Result":
        """Build a CHECK_ERROR Result for ``check`` (an exception prevented its completion).

        The Result carries a single CheckError coded ``E0`` whose message is
        ``"{exceptionName}: {exceptionMessage}"``.
        """
        error = CheckError(INTERNAL_ERROR_CODE, "{}: {}".format(type(exception).__name__, exception))
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.CHECK_ERROR,
            errors=[error],
        )

    @staticmethod
    def failure(
        check, errors: Optional[List[CheckError]] = None, warnings: Optional[List[CheckWarning]] = None
    ) -> "Result":
        """Build a FAILURE Result for ``check``; ``errors`` are the failure modes, ``warnings`` any warnings."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.FAILURE,
            errors=errors,
            warnings=warnings,
        )

    @staticmethod
    def warning(check, warnings: Optional[List[CheckWarning]] = None) -> "Result":
        """Build a WARNING Result for ``check`` (its condition holds, but ``warnings`` were raised).

        A WARNING Result is considered successful: it does not make the run fail.
        """
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.WARNING,
            warnings=warnings,
        )

    @staticmethod
    def skipped_by_user(check, infos: Optional[List[CheckInfo]] = None) -> "Result":
        """Build a SKIPPED_BY_USER Result for ``check`` (the user did not approve its execution)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.SKIPPED_BY_USER,
            infos=infos,
        )

    @staticmethod
    def skipped_not_applicable(check, infos: Optional[List[CheckInfo]] = None) -> "Result":
        """Build a SKIPPED_NOT_APPLICABLE Result for ``check`` (it does not apply to the context)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.SKIPPED_NOT_APPLICABLE,
            infos=infos,
        )
