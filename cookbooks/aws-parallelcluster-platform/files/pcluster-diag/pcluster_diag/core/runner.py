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

"""Execution engine for the diagnostic Checks.

Runs the Checks in registration order, isolating failures, and aggregates
their Results in that same order.
"""

import logging
from typing import List

from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.result import FAILED_STATUSES, Result, Status

logger = logging.getLogger(__name__)


class Runner:
    """Executes the Checks and aggregates their Results, one Result per Check, in registration order.

    Checks that run execute in isolation (an unhandled exception becomes a CHECK_ERROR Result), and a
    FAILURE or CHECK_ERROR never stops the run. Non-applicable Checks are recorded as SKIPPED_NOT_APPLICABLE
    and declined confirmation-required Checks as SKIPPED_BY_USER. Each outcome is logged to stderr
    and never alters the JSON Report.
    """

    def execute(
        self,
        context: Context,
        checks: List[Check],
        check_not_applicable: List[Check] = (),
        check_not_approved: List[Check] = (),
    ) -> List[Result]:
        """Run ``checks`` in order, one Result per Check, preserving the order of ``checks``.

        Each Check in ``checks`` is handled in order and, based on its disposition:

        - recorded SKIPPED_NOT_APPLICABLE when it is in ``check_not_applicable``;
        - recorded SKIPPED_BY_USER when it is in ``check_not_approved``;
        - otherwise executed in isolation (an unhandled exception becomes a CHECK_ERROR Result).

        Args:
            context: The runtime Context for this diagnosis.
            checks: Every Check to account for, in registration order.
            check_not_applicable: Non-applicable Checks to record as SKIPPED_NOT_APPLICABLE.
            check_not_approved: Confirmation-required Checks the user declined,
                recorded as SKIPPED_BY_USER.

        Returns:
            One Result per Check in ``checks``, in the same (registration) order.
        """
        not_applicable_ids = {check.identifier for check in check_not_applicable}
        not_approved_ids = {check.identifier for check in check_not_approved}
        results: List[Result] = []
        for check in checks:
            if check.identifier in not_applicable_ids:
                result = Result.skipped_not_applicable(check)
            elif check.identifier in not_approved_ids:
                result = Result.skipped_by_user(check)
            else:
                result = self._execute_check(context, check)
            self._collect_result(results, result)
        return results

    def _collect_result(self, results: List[Result], result: Result) -> None:
        """Record and log the outcome for one Check."""
        results.append(result)
        self._print_outcome(result)

    @staticmethod
    def _print_outcome(result: Result) -> None:
        """Log a per-Check outcome line to stderr; never alters the JSON Report.

        FAILURE and CHECK_ERROR outcomes are logged at error level; WARNING at warning level; PASSED
        and SKIPPED_* at info level.
        """
        line = "%s: %s" % (result.check_id, result.status.value)
        if result.status in FAILED_STATUSES:
            logger.error(line)
        elif result.status is Status.WARNING:
            logger.warning(line)
        else:
            logger.info(line)

    def _execute_check(self, context: Context, check: Check) -> Result:
        """Run the Check in isolation, converting any unexpected error into a CHECK_ERROR Result."""
        logger.info("Check %s: started", check.identifier)
        try:
            return check.run(context)
        except Exception as exception:  # noqa: B902 - isolation: any failure becomes a CHECK_ERROR Result
            return Result.error(check, exception)
        finally:
            logger.info("Check %s: finished", check.identifier)
