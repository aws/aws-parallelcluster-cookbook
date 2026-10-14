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

"""Unit tests for the cvtsudoers-based sudoers definitions helpers."""

import json
import subprocess

import pytest

from pcluster_diag.models.sudoer_definition import SudoerDefinition
from pcluster_diag.util import sudoers

_VENV = "/opt/parallelcluster/pyenv/versions/3.12.11/envs/node_virtualenv/bin"

# Recorded 'cvtsudoers -f json -e /etc/sudoers' output (AL2023, sudo 1.9.15) for the distro rules plus
# ParallelCluster's, extended with negated members, a rule naming no runas user and a group-only runas.
_EXPORT = {
    "Defaults": [{"Options": [{"env_reset": True}]}],
    "User_Specs": [
        {
            "User_List": [{"username": "root"}],
            "Host_List": [{"hostname": "ALL"}],
            "Cmnd_Specs": [
                {"runasusers": [{"username": "ALL"}], "Options": [{"setenv": True}], "Commands": [{"command": "ALL"}]}
            ],
        },
        {
            "User_List": [{"usergroup": "wheel"}],
            "Host_List": [{"hostname": "ALL"}],
            "Cmnd_Specs": [
                {"runasusers": [{"username": "ALL"}], "Options": [{"setenv": True}], "Commands": [{"command": "ALL"}]}
            ],
        },
        {
            "User_List": [{"username": "pcluster-admin"}],
            "Host_List": [{"hostname": "ALL"}],
            "Cmnd_Specs": [
                {
                    "runasusers": [{"username": "root"}],
                    "Options": [{"authenticate": False}],
                    "Commands": [
                        {"command": "/opt/slurm/bin/scontrol"},
                        {"command": "/opt/slurm/bin/sinfo"},
                        {
                            "command": "/usr/bin/cinc-client --local-mode --override-runlist "
                            "aws-parallelcluster-entrypoints::update_computefleet_status"
                        },
                    ],
                }
            ],
        },
        {
            "User_List": [{"username": "slurm"}],
            "Host_List": [{"hostname": "ALL"}],
            "Cmnd_Specs": [
                {
                    "runasusers": [{"username": "pcluster-admin"}],
                    "Options": [{"authenticate": False}, {"setenv": True}],
                    "Commands": [{"command": _VENV + "/slurm_resume"}],
                }
            ],
        },
        {
            "User_List": [{"username": "munge"}],
            "Host_List": [{"hostname": "ALL"}],
            "Cmnd_Specs": [{"Commands": [{"command": "/bin/a"}, {"command": "/bin/b", "negated": True}]}],
        },
        {
            "User_List": [{"username": "munge", "negated": True}, {"username": "nobody"}],
            "Host_List": [{"hostname": "ALL"}],
            "Cmnd_Specs": [
                {
                    "runasusers": [{"username": ""}],
                    "runasgroups": [{"usergroup": "wheel"}],
                    "Commands": [{"command": "/bin/c"}],
                }
            ],
        },
    ],
}


def _completed(returncode=0, stdout="", stderr=""):
    return subprocess.CompletedProcess(args=[], returncode=returncode, stdout=stdout, stderr=stderr)


@pytest.fixture
def definitions(monkeypatch):
    monkeypatch.setattr(sudoers, "run_command", lambda *_, **__: _completed(stdout=json.dumps(_EXPORT)))
    return sudoers.load_definitions("/etc/sudoers")


def test_load_definitions_runs_cvtsudoers(monkeypatch):
    calls = []
    monkeypatch.setattr(sudoers, "run_command", lambda command, **_: calls.append(command) or _completed(stdout="{}"))

    assert sudoers.load_definitions("/etc/sudoers") == []
    assert calls == [["cvtsudoers", "-f", "json", "-e", "/etc/sudoers"]]


def test_load_definitions_flattens_each_rule_into_definitions(definitions):
    cinc = (
        "/usr/bin/cinc-client --local-mode --override-runlist "
        "aws-parallelcluster-entrypoints::update_computefleet_status"
    )
    assert definitions == [
        SudoerDefinition("root", "ALL", "ALL", nopasswd=False, setenv=True),
        # %wheel defines nothing: groups are not resolved.
        SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/scontrol", nopasswd=True, setenv=False),
        SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/sinfo", nopasswd=True, setenv=False),
        SudoerDefinition("pcluster-admin", "root", cinc, nopasswd=True, setenv=False),
        SudoerDefinition("slurm", "pcluster-admin", _VENV + "/slurm_resume", nopasswd=True, setenv=True),
        # No runas user: runs as root. The negated command /bin/b defines nothing.
        SudoerDefinition("munge", "root", "/bin/a", nopasswd=False, setenv=False),
        # Negated user munge defines nothing; a group-only runas names no runas user.
        SudoerDefinition("nobody", "", "/bin/c", nopasswd=False, setenv=False),
    ]


@pytest.mark.parametrize(
    "returncode, stderr, message",
    [
        (1, "/etc/sudoers.d/zz:1:37: syntax error\n", "/etc/sudoers.d/zz:1:37: syntax error"),
        (1, "", "cvtsudoers exited with code 1"),
    ],
)
def test_load_definitions_raises_when_cvtsudoers_fails(monkeypatch, returncode, stderr, message):
    monkeypatch.setattr(sudoers, "run_command", lambda *_, **__: _completed(returncode, stderr=stderr))

    with pytest.raises(sudoers.SudoersExportError, match=message):
        sudoers.load_definitions("/etc/sudoers")
