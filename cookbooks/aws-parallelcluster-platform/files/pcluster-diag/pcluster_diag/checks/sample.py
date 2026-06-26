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

"""A placeholder Check that exercises the confirmation-gated execution path."""

from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.result import Result


class SampleCheck(Check):
    """A no-op Check that requires confirmation and always passes (exercises the approval path)."""

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Placeholder check that requires confirmation and always passes."

    def approval_required(self, context: Context) -> bool:
        """Require confirmation before running."""
        return True

    def run(self, context: Context) -> Result:
        """Pass without inspecting anything."""
        return Result.passed(self)
