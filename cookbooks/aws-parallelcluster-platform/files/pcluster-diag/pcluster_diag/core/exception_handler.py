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

"""Centralized translation of command exceptions into structured JSON errors and a clean exit."""

import json
import logging
import traceback

from pcluster_diag.models.exceptions import DiagnosticCheckNotPassedError, ExitCode

logger = logging.getLogger(__name__)


class ExceptionHandler:
    """Turns an exception raised by a CLI command into a structured JSON error and a clean exit."""

    def handle(self, error: Exception) -> None:
        """Handle any exception raised by the CLI.

        * Click exceptions: re-raised without logging, as they are expected control flow, such as
          the exceptions raised by --help/--version.
        * DiagnosticCheckNotPassedError: exits with its specific error code without logging, because
          the diagnostic report already contains the details of the failed checks.
        * Any other exception: logs the error, prints the error description as JSON, and exits with
          the error's exit code (or the internal-error code when it has none).
        """
        if self._is_click_exception(error):
            raise error
        # The failed checks are already reported in the diagnostic report, so only exit with the code.
        if isinstance(error, DiagnosticCheckNotPassedError):
            raise SystemExit(error.exit_code) from error
        logger.error("%s: %s", type(error).__name__, error, exc_info=error)
        print(json.dumps(self._error_to_dict(error), indent=2))
        raise SystemExit(getattr(error, "exit_code", ExitCode.INTERNAL_ERROR)) from error

    @staticmethod
    def _error_to_dict(error: Exception) -> dict:
        """Render an exception as ``{"errorType", "errorMessage"}`` (message falls back to the stack trace)."""
        stack_trace = "".join(traceback.format_exception(type(error), error, error.__traceback__))
        return {"errorType": type(error).__name__, "errorMessage": str(error) or stack_trace}

    @staticmethod
    def _is_click_exception(error: Exception) -> bool:
        """Return whether ``error`` is any exception defined by the Click library."""
        return any(klass.__module__.split(".")[0] == "click" for klass in type(error).__mro__)
