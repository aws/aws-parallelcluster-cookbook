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

"""Findings reported by a Check: a code and a message (error ``E<N>``, warning ``W<N>``, info ``I<N>``)."""

import copy
from dataclasses import dataclass


@dataclass
class CheckFinding:
    """A single item reported by a Check: a ``code`` and a ``message``."""

    code: str
    message: str

    def format(self, *args) -> "CheckFinding":
        """Return a copy with ``message`` formatted using ``args``."""
        formatted = copy.copy(self)
        formatted.message = self.message.format(*args)
        return formatted


class CheckError(CheckFinding):
    """A finding coded ``E<code>`` (e.g. ``CheckError(1, ...)`` has code ``E1``)."""

    def __init__(self, code: int, message: str):
        """Build an error finding with code ``E<code>`` and the given ``message``."""
        super().__init__("E{}".format(code), message)


class CheckWarning(CheckFinding):
    """A finding coded ``W<code>`` (e.g. ``CheckWarning(1, ...)`` has code ``W1``)."""

    def __init__(self, code: int, message: str):
        """Build a warning finding with code ``W<code>`` and the given ``message``."""
        super().__init__("W{}".format(code), message)


class CheckInfo(CheckFinding):
    """A finding coded ``I<code>`` (e.g. ``CheckInfo(1, ...)`` has code ``I1``)."""

    def __init__(self, code: int, message: str):
        """Build an informational finding with code ``I<code>`` and the given ``message``."""
        super().__init__("I{}".format(code), message)
