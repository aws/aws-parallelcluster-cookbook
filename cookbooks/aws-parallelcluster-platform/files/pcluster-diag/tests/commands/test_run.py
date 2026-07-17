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

"""Unit tests for the ``run`` subcommand: selection, confirmation gating, report emission, and errors."""

import json
import os

import pytest
from click.testing import CliRunner

from pcluster_diag.cli import main
from pcluster_diag.commands import run as run_module
from pcluster_diag.commands.run import run
from pcluster_diag.core.registry import Registry
from pcluster_diag.models.exceptions import ContextBuildError
from pcluster_diag.models.report import OUTPUT_DIR_NAME, Report
from pcluster_diag.models.result import Status
from tests.sample_data import FakeCheck, sample_context

# Seam for the independently-built Context: the `run` command does ``ContextBuilder().build()``.
_CONTEXT_BUILD = "pcluster_diag.core.context_builder.ContextBuilder.build"


@pytest.fixture
def runner():
    # stdout carries only the JSON document; logs go to stderr (kept separate by CliRunner).
    return CliRunner()


@pytest.fixture
def stub_context(monkeypatch):
    """Stub the independently-built Context and use an empty registry so a default `run` selects no Checks."""
    monkeypatch.setattr(_CONTEXT_BUILD, lambda self: sample_context())
    monkeypatch.setattr("pcluster_diag.commands.run.DEFAULT_REGISTRY", Registry())


def _stub_registry_with(monkeypatch, checks):
    """Make `run` build a canned Context and evaluate a registry populated with the given checks."""
    registry = Registry()
    for check in checks:
        registry.register(check)
    monkeypatch.setattr(_CONTEXT_BUILD, lambda self: sample_context())
    monkeypatch.setattr(run_module, "DEFAULT_REGISTRY", registry)


def test_run_help(runner):
    result = runner.invoke(main, ["run", "--help"])
    assert result.exit_code == 0
    assert "Usage:" in result.output


@pytest.mark.parametrize(
    "target, args",
    [(main, ["run"]), (run, [])],
    ids=["via-group", "direct-command"],
)
def test_run_emits_report_on_success(runner, stub_context, target, args):
    result = runner.invoke(target, args)
    assert result.exit_code == 0
    payload = json.loads(result.stdout)
    # On success stdout is the serialized report itself (context + results), not an error.
    assert "context" in payload
    assert "results" in payload
    assert "errorType" not in payload


_CONTEXT_BUILD_ERROR_MESSAGE = (
    "Failed to build the diagnostic context. pcluster-diag is meant to run on an AWS ParallelCluster node. "
    "This failure most likely means it is not running on a cluster node. "
    "Underlying error: [Errno 2] No such file or directory: '/etc/chef/dna.json'"
)


@pytest.mark.parametrize(
    "exception, expected_exit_code, expected_error_type, expect_traceback",
    [
        (ContextBuildError(_CONTEXT_BUILD_ERROR_MESSAGE), 2, "ContextBuildError", False),
        (RuntimeError("something unexpected broke"), 1, "RuntimeError", False),
        (RuntimeError(), 1, "RuntimeError", True),
    ],
    ids=["context-build-error", "unexpected-runtime-error", "message-less-falls-back-to-stack-trace"],
)
def test_run_emits_structured_error(
    runner, monkeypatch, exception, expected_exit_code, expected_error_type, expect_traceback
):
    def _boom(self):
        raise exception

    monkeypatch.setattr(_CONTEXT_BUILD, _boom)

    result = runner.invoke(main, ["run"])

    # No report could be produced; stdout carries the structured error and the run exits with the
    # exception-specific code.
    assert result.exit_code == expected_exit_code
    payload = json.loads(result.stdout)
    assert payload["errorType"] == expected_error_type
    if expect_traceback:
        # A message-less exception falls back to reporting its stack trace.
        assert "Traceback (most recent call last)" in payload["errorMessage"]
    else:
        # When the exception carries a message it is reported verbatim, never as a raw traceback.
        assert payload["errorMessage"] == str(exception)
        assert "Traceback (most recent call last)" not in result.stdout


def test_non_root_run_emits_insufficient_privileges_error(runner, monkeypatch):
    monkeypatch.setattr(os, "geteuid", lambda: 1000, raising=False)

    result = runner.invoke(main, ["run"])

    assert result.exit_code == 4
    payload = json.loads(result.stdout)
    assert payload["errorType"] == "InsufficientPrivilegesError"


def test_run_evaluates_registry_against_independently_built_context(runner, monkeypatch):
    context = sample_context()
    seen = {}

    class _RecordingRegistry(Registry):
        def select_checks(self, ctx, assume_yes=False):
            seen["context"] = ctx
            return [], [], []

    monkeypatch.setattr(_CONTEXT_BUILD, lambda self: context)
    monkeypatch.setattr(run_module, "DEFAULT_REGISTRY", _RecordingRegistry())

    result = runner.invoke(main, ["run"])

    assert result.exit_code == 0
    assert seen["context"] is context


@pytest.mark.parametrize(
    "invoke_args, cli_input, expected_ran, expect_prompt",
    [
        (["run"], "y\n", True, True),  # prompted and accepted -> runs
        (["run"], "n\n", False, True),  # prompted and declined -> skipped by the user
        (["run", "--yes"], None, True, False),  # --yes runs without prompting
    ],
    ids=["prompted-accepted", "prompted-declined", "yes-flag-bypasses-prompt"],
)
def test_confirmation_required_check_flow(runner, monkeypatch, invoke_args, cli_input, expected_ran, expect_prompt):
    events = []
    check = FakeCheck("ApprovalCheck", approval=True, events=events)
    _stub_registry_with(monkeypatch, [check])

    result = runner.invoke(main, invoke_args, input=cli_input)

    assert result.exit_code == 0
    # The check runs only when the confirmation is granted (via prompt or --yes).
    assert ("run:ApprovalCheck" in events) is expected_ran
    # The confirmation listing/prompt is emitted to stderr unless --yes bypasses it.
    assert ("require your confirmation" in result.stderr) is expect_prompt
    if not expected_ran:
        # A declined check is recorded SKIPPED_BY_USER in the report.
        # (Interactive input is echoed onto stdout before the JSON, so parse from the first brace.)
        assert "ApprovalCheck: SKIPPED_BY_USER" in result.stderr
        brace_at = result.stdout.index("{")
        payload = json.loads(result.stdout[brace_at:])
        assert payload["results"][0]["status"] == "SKIPPED_BY_USER"


@pytest.mark.parametrize(
    "checks_spec, expected_exit_code",
    [
        ([("PassedCheck", Status.PASSED, True), ("SkippedCheck", Status.PASSED, False)], 0),
        ([("HealthyCheck", Status.PASSED, True), ("WarnedCheck", Status.WARNING, True)], 0),
        ([("HealthyCheck", Status.PASSED, True), ("FailingCheck", Status.FAILURE, True)], 3),
        ([("ErroringCheck", Status.CHECK_ERROR, True)], 3),
    ],
    ids=[
        "all-successful-exit-zero",
        "warnings-only-exit-zero",
        "any-failure-exits-non-zero",
        "any-error-exits-non-zero",
    ],
)
def test_run_exit_code_reflects_worst_result_status(runner, monkeypatch, checks_spec, expected_exit_code):
    # A single FAILURE or ERROR makes the whole run unsuccessful; the report is still printed and the
    # handler exits with the diagnostic-failure code without emitting a separate JSON error.
    checks = [FakeCheck(name, status=status, applicable=applicable) for name, status, applicable in checks_spec]
    _stub_registry_with(monkeypatch, checks)

    result = runner.invoke(main, ["run"])

    assert result.exit_code == expected_exit_code
    report, _ = json.JSONDecoder().raw_decode(result.stdout)
    assert "results" in report
    assert "errorType" not in report


def test_report_write_failure_is_logged_but_report_is_still_emitted(runner, monkeypatch):
    check = FakeCheck("HealthyCheck", status=Status.PASSED)
    _stub_registry_with(monkeypatch, [check])

    def boom(self, path):
        raise OSError("disk full")

    monkeypatch.setattr(Report, "save", boom)

    result = runner.invoke(main, ["run"])

    # A write failure does not crash the run: the report is still emitted on stdout (report takes
    # precedence over the error), and the failure is only logged to stderr.
    assert result.exit_code == 0
    payload = json.loads(result.stdout)
    assert payload["results"][0]["check_id"] == check.identifier
    assert "errorType" not in payload
    assert "Could not write the JSON report file" in result.stderr


@pytest.mark.parametrize("use_output_file_option", [False, True], ids=["default-cwd", "custom-output-file"])
def test_run_writes_json_report_to_expected_location(runner, monkeypatch, tmp_path, use_output_file_option):
    check = FakeCheck("HealthyCheck", status=Status.PASSED)
    _stub_registry_with(monkeypatch, [check])

    if use_output_file_option:
        target = tmp_path / "reports" / "my-report.json"
        result = runner.invoke(main, ["run", "--output-file", str(target)])
        assert result.exit_code == 0
        # The report is written to the exact file requested.
        assert target.exists()
    else:
        result = runner.invoke(main, ["run"])
        assert result.exit_code == 0
        # The default is a timestamped file under ./pcluster-diag-output.
        written = os.listdir(os.path.join(os.getcwd(), OUTPUT_DIR_NAME))
        assert any(name.startswith("pcluster-diag-report-") and name.endswith(".json") for name in written)
