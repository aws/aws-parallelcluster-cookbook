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

"""Unit tests for the top-level CLI group (help, version, and the console-script entry point)."""

import pytest
from click.testing import CliRunner

from pcluster_diag import __version__
from pcluster_diag.cli import main


@pytest.fixture
def runner():
    return CliRunner()


@pytest.mark.parametrize("command", ["run", "describe-checks"])
def test_group_help_lists_commands(runner, command):
    result = runner.invoke(main, ["--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output
    assert command in result.output


def test_group_version_matches_package_version(runner):
    result = runner.invoke(main, ["--version"])
    assert result.exit_code == 0
    assert __version__ in result.output
