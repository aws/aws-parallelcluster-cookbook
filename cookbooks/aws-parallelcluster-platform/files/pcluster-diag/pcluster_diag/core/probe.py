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

"""Helpers for running a diagnostic probe in isolation and recording an unexpected failure as a finding.

A capability Check composed of several probes uses these so one probe's crash becomes an unexpected-error
finding (which ``Result.from_findings`` reports as CHECK_ERROR) instead of aborting the whole check and
discarding the findings the other probes already produced. This logic manipulates models, so it lives in
``core`` rather than in the model package.
"""

import logging
from typing import Callable, List

from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import INTERNAL_ERROR_CODE

logger = logging.getLogger(__name__)


def unexpected_error_finding(detail: str) -> CheckError:
    """Return the shared unexpected-error finding (code E0) for an uncaught failure inside a check/probe."""
    return CheckError(
        INTERNAL_ERROR_CODE, "A diagnostic probe did not complete due to an unexpected error: {}".format(detail)
    )


def run_probe(label: str, probe: Callable[[], None], errors: List[CheckError]) -> None:
    """Run ``probe`` in isolation, converting an unexpected exception into a shared E0 error finding.

    ``probe`` is a zero-argument callable that records its own findings as a side effect; ``errors`` is the
    shared error list the crash finding is appended to. Expected conditions are handled inside each probe;
    only an unexpected exception is caught here so one probe's crash does not sink its siblings' findings.
    """
    try:
        probe()
    except Exception as exc:  # noqa: B902 - isolation: one probe's crash must not sink the others
        logger.exception("Diagnostic probe '%s' failed unexpectedly", label)
        errors.append(unexpected_error_finding("{} ({}: {})".format(label, type(exc).__name__, exc)))
