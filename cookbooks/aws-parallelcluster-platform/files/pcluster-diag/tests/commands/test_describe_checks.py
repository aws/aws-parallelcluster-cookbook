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

"""Unit tests for the ``describe-checks`` subcommand: the JSON catalog of the registered checks."""

import json
import os

import pytest
from click.testing import CliRunner

from pcluster_diag.cli import main
from pcluster_diag.commands import describe_checks as describe_checks_module
from pcluster_diag.commands.describe_checks import describe_checks
from pcluster_diag.core.registry import DEFAULT_REGISTRY, Registry
from tests.sample_data import FakeCheck


@pytest.fixture
def runner():
    # stdout carries only the JSON document; logs go to stderr (kept separate by CliRunner).
    return CliRunner()


def _stub_registry_with(monkeypatch, checks):
    """Make `describe-checks` describe a registry populated with the given checks."""
    registry = Registry()
    for check in checks:
        registry.register(check)
    monkeypatch.setattr(describe_checks_module, "DEFAULT_REGISTRY", registry)


def test_describe_checks_help(runner):
    result = runner.invoke(main, ["describe-checks", "--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output


@pytest.mark.parametrize(
    "target, args",
    [(main, ["describe-checks"]), (describe_checks, [])],
    ids=["via-group", "direct-command"],
)
def test_describe_checks_emits_catalog_in_registration_order(runner, monkeypatch, target, args):
    _stub_registry_with(
        monkeypatch,
        [
            FakeCheck("FirstCheck", description="what the first check verifies"),
            FakeCheck("SecondCheck", description="what the second check verifies"),
        ],
    )

    result = runner.invoke(target, args)

    assert result.exit_code == 0
    # stdout is the catalog itself: every registered check, with identifier and description, in order.
    assert json.loads(result.stdout) == [
        {"check_id": "FirstCheck", "check_description": "what the first check verifies"},
        {"check_id": "SecondCheck", "check_description": "what the second check verifies"},
    ]


def test_describe_checks_emits_empty_catalog_when_nothing_is_registered(runner, monkeypatch):
    _stub_registry_with(monkeypatch, [])

    result = runner.invoke(main, ["describe-checks"])

    assert result.exit_code == 0
    assert json.loads(result.stdout) == []


def test_describe_checks_executes_no_check(runner, monkeypatch):
    events = []
    check = FakeCheck("SomeCheck", events=events)
    _stub_registry_with(monkeypatch, [check])

    result = runner.invoke(main, ["describe-checks"])

    assert result.exit_code == 0
    # Describing the registry neither evaluates applicability nor runs anything.
    assert events == []
    assert check.ran is False


def test_describe_checks_does_not_require_root(runner, monkeypatch):
    monkeypatch.setattr(os, "geteuid", lambda: 1000, raising=False)
    _stub_registry_with(monkeypatch, [FakeCheck("SomeCheck")])

    result = runner.invoke(main, ["describe-checks"])

    assert result.exit_code == 0
    assert json.loads(result.stdout)[0]["check_id"] == "SomeCheck"


def test_describe_checks_describes_the_default_registry(runner):
    result = runner.invoke(main, ["describe-checks"])

    assert result.exit_code == 0
    described = {entry["check_id"]: entry["check_description"] for entry in json.loads(result.stdout)}
    assert described == {check.identifier: check.description for check in DEFAULT_REGISTRY.registered_checks()}
