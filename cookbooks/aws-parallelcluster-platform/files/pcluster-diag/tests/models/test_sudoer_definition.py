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

"""Unit tests for the SudoerDefinition model."""

import pytest

from pcluster_diag.models.sudoer_definition import SudoerDefinition


@pytest.mark.parametrize(
    "definition, expected",
    [
        (SudoerDefinition("pcluster-admin", "root", "/bin/a"), "pcluster-admin ALL = (root) NOPASSWD: /bin/a"),
        (
            SudoerDefinition("slurm", "pcluster-admin", "/bin/b", setenv=True),
            "slurm ALL = (pcluster-admin) NOPASSWD:SETENV: /bin/b",
        ),
        (SudoerDefinition("root", "ALL", "ALL", nopasswd=False), "root ALL = (ALL) ALL"),
    ],
)
def test_str_renders_sudoers_syntax(definition, expected):
    assert str(definition) == expected


def test_equality_includes_tags():
    assert SudoerDefinition("u", "root", "/bin/a") == SudoerDefinition("u", "root", "/bin/a", nopasswd=True)
    assert SudoerDefinition("u", "root", "/bin/a") != SudoerDefinition("u", "root", "/bin/a", setenv=True)
