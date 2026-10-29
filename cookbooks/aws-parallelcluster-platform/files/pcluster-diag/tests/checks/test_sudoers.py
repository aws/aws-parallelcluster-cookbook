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

"""Unit tests for the Sudoers check, driven by sudoers files."""

import dataclasses
import os
import shutil

import pytest

from pcluster_diag.checks import sudoers as sudoers_check
from pcluster_diag.checks.sudoers import EXPECTED_DEFINITIONS, Sudoers
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.models.sudoer_definition import SudoerDefinition
from pcluster_diag.util import sudoers
from tests.sample_data import sample_context

# The real loader, kept before tests patch the module attribute the check calls.
_LOAD_DEFINITIONS = sudoers.load_definitions
_VENV = "/opt/parallelcluster/pyenv/versions/3.12.11/envs/node_virtualenv/bin"
_SCONTROL = SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/scontrol")
_RESUME = SudoerDefinition("slurm", "pcluster-admin", _VENV + "/slurm_resume", setenv=True)
_ROOT = SudoerDefinition("root", "ALL", "ALL", nopasswd=False, setenv=True)
_LOGIN_HOOK = SudoerDefinition("pcluster-admin", "root", "/etc/hook.sh")

_ROOT_RULE = SudoerDefinition("root", "ALL", "ALL", nopasswd=False, setenv=True)
_SCONTROL_RULE = SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/scontrol", nopasswd=True, setenv=False)
_SINFO_RULE = SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/sinfo", nopasswd=True, setenv=False)
_RESUME_RULE = SudoerDefinition("slurm", "pcluster-admin", _VENV + "/slurm_resume", nopasswd=True, setenv=True)
_HEALTHY = [_ROOT_RULE, _SCONTROL_RULE, _SINFO_RULE, _RESUME_RULE]


@pytest.fixture
def policy(monkeypatch):
    """Serve the given definitions to the check; return a function replacing them."""
    served = {"definitions": list(_HEALTHY)}
    monkeypatch.setattr(sudoers_check.sudoers_policy, "load_definitions", lambda _path: served["definitions"])
    monkeypatch.setattr(sudoers_check.virtualenvs, "node_virtualenv_bin", lambda: _VENV)

    def _serve(definitions):
        served["definitions"] = definitions

    return _serve


@pytest.fixture
def run_check(monkeypatch):
    """Return a function running the check on ``node_type`` with only ``expected_definitions`` expected there."""

    def _run(expected_definitions, node_type=NodeType.HEAD):
        monkeypatch.setitem(sudoers_check.EXPECTED_DEFINITIONS, node_type, expected_definitions)
        return Sudoers().run(sample_context(node_type))

    return _run


def _codes(result):
    return [error.code for error in (result.errors or [])]


def _messages(result):
    return " | ".join(error.message for error in (result.errors or []))


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_applies_to_every_node_type(node_type):
    assert Sudoers().should_run(sample_context(node_type)) is True
    assert Sudoers().approval_required(sample_context(node_type)) is False


def test_passes_when_every_expected_definition_is_present(policy, run_check):
    result = run_check([_SCONTROL, _RESUME, _ROOT])

    assert result.status is Status.PASSED, _messages(result)


def test_inspects_only_definitions_of_current_node_type(policy, monkeypatch):
    monkeypatch.setattr(
        sudoers_check,
        "EXPECTED_DEFINITIONS",
        {NodeType.HEAD: [_SCONTROL], NodeType.COMPUTE: [], NodeType.LOGIN: [_SCONTROL, _LOGIN_HOOK]},
    )

    assert Sudoers().run(sample_context(NodeType.HEAD)).status is Status.PASSED
    assert _codes(Sudoers().run(sample_context(NodeType.LOGIN))) == [Sudoers.NOT_DEFINED.code]
    assert Sudoers().run(sample_context(NodeType.COMPUTE)).status is Status.PASSED  # nothing expected there


def test_fails_when_root_definition_is_missing(policy, run_check):
    # Host hardening replaced /etc/sudoers, dropping root's rule.
    policy([_SCONTROL_RULE])

    result = run_check([_SCONTROL, _ROOT])

    assert _codes(result) == [Sudoers.NOT_DEFINED.code]
    assert "do not contain the expected definition: root ALL = (ALL) SETENV: ALL." in _messages(result)


def test_fails_when_parallelcluster_definitions_are_missing(policy, run_check):
    # e.g. the #includedir was dropped from /etc/sudoers, so only root's rule is left.
    policy([_ROOT_RULE])

    result = run_check([_SCONTROL, _RESUME, _ROOT])

    assert _codes(result) == [Sudoers.NOT_DEFINED.code] * 2
    assert "slurm ALL = (pcluster-admin) NOPASSWD:SETENV: {}/slurm_resume".format(_VENV) in _messages(result)


@pytest.mark.parametrize(
    "actual",
    [
        SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/scontrol", nopasswd=False),  # NOPASSWD lost
        SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/scontrol", setenv=True),  # extra SETENV
        SudoerDefinition("pcluster-admin", "ALL", "/opt/slurm/bin/scontrol"),  # broader runas
        SudoerDefinition("pcluster-admin", "root", "ALL"),  # broader command
        SudoerDefinition("pcluster-admin", "root", "/opt/slurm/bin/scontrol show"),  # different arguments
    ],
    ids=["no-nopasswd", "extra-setenv", "runas-all", "command-all", "arguments"],
)
def test_requires_the_exact_definition(policy, actual, run_check):
    policy([actual])

    result = run_check([_SCONTROL])

    assert _codes(result) == [Sudoers.NOT_DEFINED.code]
    assert "pcluster-admin ALL = (root) NOPASSWD: /opt/slurm/bin/scontrol" in _messages(result)


@pytest.mark.parametrize(
    "pcluster_version, log_level",
    [("3.11.0", "auto"), ("3.14.1", "auto"), ("3.15.0", "info"), ("3.16.2", "info"), ("unknown", "info")],
)
def test_expects_the_clusterstatusmgtd_log_level_of_the_parallelcluster_version(
    policy, monkeypatch, pcluster_version, log_level
):
    # clusterstatusmgtd runs cinc-client with --log_level info since ParallelCluster 3.15.0, and auto before.
    command = sudoers_check.CLUSTERSTATUSMGTD_CINC_COMMAND.format(cinc_log_level=log_level)
    policy([SudoerDefinition("pcluster-admin", "root", command)])
    expected = SudoerDefinition("pcluster-admin", "root", sudoers_check.CLUSTERSTATUSMGTD_CINC_COMMAND)
    monkeypatch.setitem(sudoers_check.EXPECTED_DEFINITIONS, NodeType.HEAD, [expected])
    context = dataclasses.replace(sample_context(), pcluster_version=pcluster_version)

    result = Sudoers().run(context)

    assert result.status is Status.PASSED, _messages(result)


def test_fails_when_clusterstatusmgtd_log_level_does_not_match_the_parallelcluster_version(policy, monkeypatch):
    command = sudoers_check.CLUSTERSTATUSMGTD_CINC_COMMAND.format(cinc_log_level="info")
    policy([SudoerDefinition("pcluster-admin", "root", command)])
    expected = SudoerDefinition("pcluster-admin", "root", sudoers_check.CLUSTERSTATUSMGTD_CINC_COMMAND)
    monkeypatch.setitem(sudoers_check.EXPECTED_DEFINITIONS, NodeType.HEAD, [expected])
    context = dataclasses.replace(sample_context(), pcluster_version="3.14.0")

    result = Sudoers().run(context)

    assert _codes(result) == [Sudoers.NOT_DEFINED.code]
    assert "--log_level auto" in _messages(result)


def test_fails_when_sudoers_cannot_be_read(monkeypatch, run_check):
    def _fail(_path):
        raise sudoers.SudoersExportError("/etc/sudoers.d/zz:1:37: syntax error")

    monkeypatch.setattr(sudoers_check.sudoers_policy, "load_definitions", _fail)

    result = run_check([_SCONTROL])

    assert result.status is Status.FAILURE
    assert _codes(result) == [Sudoers.INVALID_SUDOERS.code]
    assert "The sudoers files cannot be read: /etc/sudoers.d/zz:1:37: syntax error" in _messages(result)


def test_reads_etc_sudoers(monkeypatch):
    paths = []
    monkeypatch.setattr(sudoers_check.sudoers_policy, "load_definitions", lambda path: paths.append(path) or [])
    monkeypatch.setattr(sudoers_check.virtualenvs, "node_virtualenv_bin", lambda: _VENV)

    monkeypatch.setitem(sudoers_check.EXPECTED_DEFINITIONS, NodeType.HEAD, [])

    Sudoers().run(sample_context())

    assert paths == ["/etc/sudoers"]


def test_expected_definitions_per_node_type():
    def expected(node_type):
        return {(p.user, p.runas, p.command.split()[0]) for p in EXPECTED_DEFINITIONS[node_type]}

    everywhere = {
        ("pcluster-admin", "root", "/opt/slurm/bin/scontrol"),
        ("pcluster-admin", "root", "/opt/slurm/bin/sinfo"),
        ("pcluster-admin", "root", "/usr/sbin/shutdown"),
        ("slurm", "pcluster-admin", "{node_virtualenv_bin}/slurm_resume"),
        ("slurm", "pcluster-admin", "{node_virtualenv_bin}/slurm_suspend"),
        ("slurm", "pcluster-admin", "{node_virtualenv_bin}/slurm_fleet_status_manager"),
    }
    assert expected(NodeType.HEAD) == everywhere | {
        ("pcluster-admin", "root", "/usr/bin/cinc-client"),
        ("root", "ALL", "ALL"),
    }
    assert expected(NodeType.COMPUTE) == everywhere
    assert expected(NodeType.LOGIN) == everywhere | {
        ("pcluster-admin", "root", "/etc/parallelcluster/loginmgtd_on_termination.sh")
    }


def test_cookbook_templates_contain_the_expected_definitions(tmp_path, monkeypatch):
    """The cookbook's sudoers templates, rendered, contain every definition expected on each node type."""
    cookbooks = os.path.join(os.path.dirname(__file__), "..", "..", "..", "..", "..")
    if not os.path.isdir(os.path.join(cookbooks, "aws-parallelcluster-slurm")):
        pytest.skip("cookbook templates are not available next to this source tree")
    if not shutil.which("cvtsudoers"):
        pytest.skip("cvtsudoers is not installed")
    templates = [
        "aws-parallelcluster-slurm/templates/default/slurm/99-parallelcluster-slurm.erb",
        "aws-parallelcluster-computefleet/templates/clusterstatusmgtd/99-parallelcluster-clusterstatusmgtd.erb",
        "aws-parallelcluster-platform/templates/loginmgtd/99-parallelcluster-loginmgtd.erb",
    ]
    renders = {
        "<%= node['cluster']['cluster_admin_user'] %>": "pcluster-admin",
        "<%= node['cluster']['slurm']['user'] %>": "slurm",
        "<%= node['cluster']['slurm']['install_dir'] %>": "/opt/slurm",
        "<%= node_virtualenv_path %>": _VENV[: -len("/bin")],
        "<%= node['cluster']['etc_dir'] %>": "/etc/parallelcluster",
    }
    # The rendered templates go in a single temporary sudoers file (never the host's /etc/sudoers), not in an
    # #includedir: cvtsudoers, like sudo, skips an include not owned by root, and tests may run as a regular user.
    rendered = ["root ALL=(ALL:ALL) ALL\n"]
    for template in templates:
        with open(os.path.join(cookbooks, template), encoding="utf-8") as template_file:
            text = template_file.read()
        for erb, value in renders.items():
            text = text.replace(erb, value)
        rendered.append(text)
    (tmp_path / "sudoers").write_text("\n".join(rendered))
    monkeypatch.setattr(
        sudoers_check.sudoers_policy, "load_definitions", lambda _path: _LOAD_DEFINITIONS(str(tmp_path / "sudoers"))
    )
    monkeypatch.setattr(sudoers_check.virtualenvs, "node_virtualenv_bin", lambda: _VENV)

    for node_type in NodeType:
        result = Sudoers().run(sample_context(node_type))
        assert result.status is Status.PASSED, "{}: {}".format(node_type, _messages(result))


def test_defaults_to_the_expected_definitions_of_the_node_type(policy):
    result = Sudoers().run(sample_context(NodeType.COMPUTE))

    # The healthy rules lack shutdown, slurm_suspend and slurm_fleet_status_manager.
    assert _codes(result) == [Sudoers.NOT_DEFINED.code] * 3
    assert "pcluster-admin ALL = (root) NOPASSWD: /usr/sbin/shutdown" in _messages(result)
