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

"""The uniform Check interface implemented by every diagnostic Check."""

from abc import ABC, abstractmethod

from pcluster_diag.models.context import Context
from pcluster_diag.models.result import Result


class Check(ABC):
    """A unit of diagnostic check."""

    @property
    def identifier(self) -> str:
        """Return the check identifier: this Check's class simple name."""
        return type(self).__name__

    @property
    @abstractmethod
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        raise NotImplementedError

    def should_run(self, context: Context) -> bool:
        """Return whether this Check applies to the given Context.

        Defaults to ``True`` (the Check applies to every Context).
        """
        return True

    def approval_required(self, context: Context) -> bool:
        """Return whether this Check requires user confirmation before running.

        Defaults to ``False``. When ``True``, the user is prompted to confirm the execution.
        """
        return False

    @abstractmethod
    def run(self, context: Context) -> Result:
        """Execute the Check and return its Result."""
        raise NotImplementedError
