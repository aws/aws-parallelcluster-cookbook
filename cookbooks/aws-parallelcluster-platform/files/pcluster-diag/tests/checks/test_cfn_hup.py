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

"""Unit tests for the CfnHup check: daemon location on every node and config-role agreement on the head node."""

import pytest

from pcluster_diag.checks import cfn_hup
from pcluster_diag.checks.cfn_hup import CfnHup
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context

_RUNNING_ON_NON_HEAD = CfnHup.RUNNING_ON_NON_HEAD_NODE


def _conf_with_role(role_line="role=my-instance-role"):
    """Return a cfn-hup.conf body carrying role_line, with mock filler for the other [main] keys."""
    return (
        "[main]\nstack=mock-stack-arn\nregion=mock-region\n"
        "url=https://mock-cfn-endpoint.example.com\n{}\n".format(role_line)
    )


def _use_cfn_hup_conf(monkeypatch, tmp_path, body):
    """Write body to a cfn-hup.conf and point the check's config path constant at it."""
    conf = tmp_path / "cfn-hup.conf"
    conf.write_text(body, encoding="utf-8")
    monkeypatch.setattr(cfn_hup, "CFN_HUP_CONF_PATH", str(conf))


def _codes(result):
    """Return the list of finding codes carried by a Result (empty list when it has none)."""
    return [error.code for error in (result.errors or [])]


def _messages(result):
    """Return the joined error messages carried by a Result."""
    return " | ".join(error.message for error in (result.errors or []))


def test_description():
    description = CfnHup().description

    assert "cfn-hup" in description
    assert "head node" in description
    assert "properly configured" in description


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_should_run(node_type):
    # The check compares actual vs expected state, so it applies on every node type.
    assert CfnHup().should_run(sample_context(node_type)) is True


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_approval_required(node_type):
    assert CfnHup().approval_required(sample_context(node_type)) is False


@pytest.mark.parametrize(
    "node_type, is_running, expected_status, expected_errors",
    [
        (NodeType.COMPUTE, False, Status.PASSED, None),  # compute: not running as expected
        (NodeType.COMPUTE, True, Status.FAILURE, [_RUNNING_ON_NON_HEAD]),  # compute: running but shouldn't be
        (NodeType.LOGIN, False, Status.PASSED, None),  # login: not running as expected
        (NodeType.LOGIN, True, Status.FAILURE, [_RUNNING_ON_NON_HEAD]),  # login: running but shouldn't be
    ],
)
def test_run_daemon_location_on_non_head_nodes(monkeypatch, node_type, is_running, expected_status, expected_errors):
    # On non-head nodes only the daemon-location concern is evaluated (the config check is head-only),
    # so the config file is never read here.
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: is_running)

    result = CfnHup().run(sample_context(node_type))

    assert result.status is expected_status
    # A failure returns the Check's own constant error; a pass carries none.
    assert result.errors == expected_errors


@pytest.mark.parametrize(
    "is_running, imds_role, configured_role, expected_status, expected_codes",
    [
        # head, cfn-hup running and roles agree: both concerns pass.
        (True, "role-a", "role-a", Status.PASSED, []),
        # head, roles agree but cfn-hup is down: only the daemon-location failure.
        (False, "role-a", "role-a", Status.FAILURE, [CfnHup.NOT_RUNNING_ON_HEAD_NODE.code]),
        # head, cfn-hup running but the configured role is stale: only the role mismatch.
        (True, "new-role", "old-role", Status.FAILURE, [CfnHup.ROLE_MISMATCH.code]),
        # head, cfn-hup down and roles disagree: both problems reported together.
        (
            False,
            "new-role",
            "old-role",
            Status.FAILURE,
            [CfnHup.NOT_RUNNING_ON_HEAD_NODE.code, CfnHup.ROLE_MISMATCH.code],
        ),
    ],
    ids=["all-pass", "daemon-down-only", "role-mismatch-only", "both-problems"],
)
def test_run_on_head_node_combines_daemon_and_config_checks(
    monkeypatch, tmp_path, is_running, imds_role, configured_role, expected_status, expected_codes
):
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: is_running)
    monkeypatch.setattr(cfn_hup.imds, "get_iam_role_name", lambda: imds_role)
    _use_cfn_hup_conf(monkeypatch, tmp_path, _conf_with_role("role={}".format(configured_role)))

    result = CfnHup().run(sample_context(NodeType.HEAD))

    assert result.status is expected_status
    assert _codes(result) == expected_codes


def test_run_reports_role_mismatch_details(monkeypatch, tmp_path):
    # cfn-hup is running (no daemon error) but the instance role was swapped and cfn-hup.conf names the old one.
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: True)
    monkeypatch.setattr(cfn_hup.imds, "get_iam_role_name", lambda: "new-role")
    _use_cfn_hup_conf(monkeypatch, tmp_path, _conf_with_role("role=old-role"))

    result = CfnHup().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CfnHup.ROLE_MISMATCH.code]
    assert "does not match the one in" in _messages(result)
    assert "new-role" in _messages(result) and "old-role" in _messages(result)


def test_run_reports_mismatch_when_config_has_no_role(monkeypatch, tmp_path):
    # A cfn-hup.conf with no role= line is reported as a mismatch whose configured value is "<missing>".
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: True)
    monkeypatch.setattr(cfn_hup.imds, "get_iam_role_name", lambda: "my-instance-role")
    _use_cfn_hup_conf(monkeypatch, tmp_path, "[main]\nregion=mock-region\n")

    result = CfnHup().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [CfnHup.ROLE_MISMATCH.code]
    assert "does not match the one in" in _messages(result)
    assert "my-instance-role" in _messages(result)
    assert "<missing>" in _messages(result)


def test_run_defers_to_imds_check_when_imds_reports_no_role(monkeypatch, tmp_path):
    # A missing IMDS role is the Imds check's concern, so CfnHup does not report a config mismatch for it.
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: True)
    monkeypatch.setattr(cfn_hup.imds, "get_iam_role_name", lambda: None)
    _use_cfn_hup_conf(monkeypatch, tmp_path, _conf_with_role("role=my-instance-role"))

    result = CfnHup().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.errors is None


def test_run_reads_role_when_other_values_contain_percent(monkeypatch, tmp_path):
    # A url-encoded value elsewhere in the file must not break reading role (no % interpolation).
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: True)
    monkeypatch.setattr(cfn_hup.imds, "get_iam_role_name", lambda: "my-instance-role")
    _use_cfn_hup_conf(monkeypatch, tmp_path, "[main]\nstack=mock%3Aencoded%3Avalue\nrole=my-instance-role\n")

    result = CfnHup().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED


def test_run_raises_when_config_file_missing(monkeypatch, tmp_path):
    # A missing cfn-hup.conf raises; the Runner maps it to a CHECK_ERROR result.
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: True)
    monkeypatch.setattr(cfn_hup.imds, "get_iam_role_name", lambda: "my-instance-role")
    monkeypatch.setattr(cfn_hup, "CFN_HUP_CONF_PATH", str(tmp_path / "absent.conf"))

    with pytest.raises(FileNotFoundError):
        CfnHup().run(sample_context(NodeType.HEAD))


def test_run_propagates_when_daemon_status_cannot_be_determined(monkeypatch):
    # An undeterminable daemon status makes the check raise (the Runner maps it to an ERROR).
    def _raise(_program):
        raise RuntimeError("cannot determine status")

    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", _raise)

    with pytest.raises(RuntimeError):
        CfnHup().run(sample_context(NodeType.COMPUTE))
