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

"""Unit tests for the sample check covering description, should_run, approval_required, and run."""

from pcluster_diag.checks.sample import SampleCheck
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context


def test_description():
    description = SampleCheck().description

    assert description == "Placeholder check that requires confirmation and always passes."


def test_should_run():
    # SampleCheck does not restrict applicability, so it runs in every context.
    assert SampleCheck().should_run(sample_context()) is True


def test_approval_required():
    assert SampleCheck().approval_required(sample_context()) is True


def test_run():
    check = SampleCheck()

    result = check.run(sample_context())

    assert result.status is Status.PASSED
    assert result.check_id == check.identifier
