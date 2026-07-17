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

"""Shared pytest fixtures and test-output isolation for the suite."""

import os

import pytest


@pytest.fixture(autouse=True)
def _isolate_working_directory(tmp_path, monkeypatch):
    """Run every test in a temporary working directory.

    Some code paths (notably the ``run`` command) write output relative to the current working
    directory. Changing into a per-test temp dir guarantees no test writes into the pcluster-diag
    project root; pytest cleans these temp dirs up automatically.
    """
    monkeypatch.chdir(tmp_path)


@pytest.fixture(autouse=True)
def _run_as_root(monkeypatch):
    """Make the process look like root by default so the ``run`` privilege check passes.

    Tests exercising the non-root path override ``os.geteuid`` themselves.
    """
    monkeypatch.setattr(os, "geteuid", lambda: 0, raising=False)
