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

"""Unit tests for the probe helpers: unexpected_error_finding and run_probe isolation."""

from pcluster_diag.core.probe import run_probe, unexpected_error_finding
from pcluster_diag.models.finding import CheckError
from pcluster_diag.models.result import INTERNAL_ERROR_CODE


def test_unexpected_error_finding_uses_reserved_e0_code():
    finding = unexpected_error_finding("backend probe (RuntimeError: boom)")

    assert finding.code == "E{}".format(INTERNAL_ERROR_CODE)
    assert "backend probe (RuntimeError: boom)" in finding.message


def test_run_probe_adds_nothing_when_probe_succeeds():
    errors = []

    run_probe("healthy probe", lambda: None, errors)

    assert errors == []


def test_run_probe_isolates_unexpected_exception_as_e0_error():
    errors = [CheckError(1, "a pre-existing expected error")]

    def crashing_probe():
        raise RuntimeError("boom")

    run_probe("backend probe", crashing_probe, errors)

    # The pre-existing finding is preserved and a single E0 finding is appended for the crash.
    assert [error.code for error in errors] == ["E1", "E{}".format(INTERNAL_ERROR_CODE)]
    assert "backend probe" in errors[1].message
    assert "RuntimeError: boom" in errors[1].message
