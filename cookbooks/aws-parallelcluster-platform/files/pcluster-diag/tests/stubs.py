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

"""Shared stub factories for the test suite.

These build argument-ignoring callables suitable for ``monkeypatch.setattr`` / ``setattr`` when a
collaborator method must be replaced with one that returns a canned value or raises.
"""


def stub_returning(value):
    """Return a stub that ignores its arguments and yields ``value``."""

    def _stub(*_args, **_kwargs):
        return value

    return _stub


def stub_raising(exception):
    """Return a stub that raises when called.

    ``exception`` may be an exception instance to raise as-is, or a message string, in which case a
    ``RuntimeError`` carrying that message is raised.
    """
    error = exception if isinstance(exception, BaseException) else RuntimeError(exception)

    def _stub(*_args, **_kwargs):
        raise error

    return _stub
