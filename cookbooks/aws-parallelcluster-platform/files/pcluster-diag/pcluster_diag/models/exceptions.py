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

"""Domain exceptions for pcluster-diag.

Every expected error derives from :class:`PclusterDiagError`; the CLI's top-level handler prints it as
JSON and exits with its ``exit_code``.
"""

import enum


class ExitCode(enum.IntEnum):
    """Process exit codes returned by the pcluster-diag CLI."""

    INTERNAL_ERROR = 1
    CONTEXT_BUILD_ERROR = 2
    DIAGNOSTIC_CHECK_FAILURE = 3
    INSUFFICIENT_PRIVILEGES = 4


class PclusterDiagError(Exception):
    """Base class for expected pcluster-diag errors."""

    #: Process exit code associated with this error type.
    exit_code: ExitCode = ExitCode.INTERNAL_ERROR
    #: User-facing message used when the error is raised without an explicit one.
    default_message: str = "An unexpected pcluster-diag error occurred."

    def __str__(self) -> str:
        """Return the explicit message when provided, otherwise the type's default message."""
        return super().__str__() or self.default_message


class ContextBuildError(PclusterDiagError):
    """Raised when the diagnostic Context cannot be built (e.g., not running on a cluster node)."""

    exit_code = ExitCode.CONTEXT_BUILD_ERROR
    default_message = "Failed to build the diagnostic context."


class DiagnosticCheckNotPassedError(PclusterDiagError):
    """Raised when at least one check did not pass (a FAILURE or CHECK_ERROR result)."""

    exit_code = ExitCode.DIAGNOSTIC_CHECK_FAILURE
    default_message = "The diagnosis detected at least one failed check."


class InsufficientPrivilegesError(PclusterDiagError):
    """Raised when the CLI is not run as root, which its checks require."""

    exit_code = ExitCode.INSUFFICIENT_PRIVILEGES
    default_message = "pcluster-diag must be run as root."
