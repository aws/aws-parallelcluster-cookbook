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
from typing import Optional


class Status(Enum):
    """The status of a Check execution."""

    PASSED = "PASSED"  # condition satisfied
    ERROR = "ERROR"  # check raised / could not complete
    FAILURE = "FAILURE"  # check completed; condition not satisfied
    SKIPPED = "SKIPPED"  # not applicable or user-skipped


# Statuses that make the run unsuccessful: any of these in the results yields a non-zero exit code.
FAILED_STATUSES = (Status.FAILURE, Status.ERROR)


@dataclass
class Result:
    """The outcome of executing a Check.

    Attributes:
        check_id: The check identifier (the Check class simple name).
        check_description: The Check's human-readable description.
        status: The Status of the execution (PASSED, ERROR, FAILURE, or SKIPPED).
        message: An optional human-readable message carrying the failure reason,
            a recovery suggestion, or an exception stack trace.
        metadata: An optional dictionary carrying any underlying data referenced by the Result.
    """

    check_id: str
    check_description: str
    status: Status
    message: Optional[str] = None
    metadata: Optional[dict] = None

    @staticmethod
    def passed(check, message: Optional[str] = None, metadata: Optional[dict] = None) -> "Result":
        """Build a PASSED Result for ``check`` (its condition was satisfied)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.PASSED,
            message=message,
            metadata=metadata,
        )

    @staticmethod
    def error(check, message: Optional[str] = None, metadata: Optional[dict] = None) -> "Result":
        """Build an ERROR Result for ``check`` (it raised or could not complete)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.ERROR,
            message=message,
            metadata=metadata,
        )

    @staticmethod
    def failure(check, message: Optional[str] = None, metadata: Optional[dict] = None) -> "Result":
        """Build a FAILURE Result for ``check`` (it completed with its condition not satisfied)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.FAILURE,
            message=message,
            metadata=metadata,
        )

    @staticmethod
    def skipped(check, message: Optional[str] = None, metadata: Optional[dict] = None) -> "Result":
        """Build a SKIPPED Result for ``check`` (not applicable or user-skipped)."""
        return Result(
            check_id=check.identifier,
            check_description=check.description,
            status=Status.SKIPPED,
            message=message,
            metadata=metadata,
        )
