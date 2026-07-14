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

"""Unit tests for the IMDS-role-vs-cfn-hup-config check."""

import pytest

from pcluster_diag.checks import instance_profile
from pcluster_diag.checks.instance_profile import ImdsRoleMatchesCfnHupConfig
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context


def _write_cfn_hup_conf(tmp_path, role_line="role=my-instance-role"):
    """Write a minimal cfn-hup.conf into tmp_path and return its path."""
    conf = tmp_path / "cfn-hup.conf"
    conf.write_text(
        "[main]\nstack=arn:aws:cloudformation:us-east-1:123:stack/x\nregion=us-east-1\n"
        "url=https://cloudformation.us-east-1.amazonaws.com\n{}\n".format(role_line),
        encoding="utf-8",
    )
    return str(conf)


def _check(tmp_path, role_line="role=my-instance-role"):
    """Build the check pointed at a cfn-hup.conf written with role_line."""
    return ImdsRoleMatchesCfnHupConfig(cfn_hup_conf_path=_write_cfn_hup_conf(tmp_path, role_line))


def _codes(result):
    """Return the list of error codes carried by a Result (empty list when it has no errors)."""
    return [error.code for error in (result.errors or [])]


def _messages(result):
    """Return the joined error messages carried by a Result."""
    return " | ".join(error.message for error in (result.errors or []))


def test_description():
    assert "IMDS" in ImdsRoleMatchesCfnHupConfig().description


@pytest.mark.parametrize(
    "node_type, expected",
    [(NodeType.HEAD, True), (NodeType.COMPUTE, False), (NodeType.LOGIN, False)],
    ids=lambda v: str(v),
)
def test_should_run_head_node_only(node_type, expected):
    # cfn-hup and its config live on the head node only.
    assert ImdsRoleMatchesCfnHupConfig().should_run(sample_context(node_type)) is expected


def test_passes_when_imds_role_matches_configured_role(monkeypatch, tmp_path):
    monkeypatch.setattr(instance_profile.imds, "get_iam_role_name", lambda: "my-instance-role")

    result = _check(tmp_path).run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.errors is None


def test_fails_when_imds_role_differs_from_configured_role(monkeypatch, tmp_path):
    # The instance role was swapped but cfn-hup.conf still names the old one.
    monkeypatch.setattr(instance_profile.imds, "get_iam_role_name", lambda: "new-role")

    result = _check(tmp_path, role_line="role=old-role").run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [ImdsRoleMatchesCfnHupConfig.ROLE_MISMATCH.code]
    assert "does not match" in _messages(result)
    assert "new-role" in _messages(result) and "old-role" in _messages(result)


def test_fails_when_imds_reports_no_role(monkeypatch, tmp_path):
    monkeypatch.setattr(instance_profile.imds, "get_iam_role_name", lambda: None)

    result = _check(tmp_path).run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [ImdsRoleMatchesCfnHupConfig.NO_ROLE_FROM_IMDS.code]
    assert "IMDS reports no IAM role" in _messages(result)


def test_fails_when_config_has_no_role(monkeypatch, tmp_path):
    monkeypatch.setattr(instance_profile.imds, "get_iam_role_name", lambda: "my-instance-role")

    # cfn-hup.conf with a [main] section but no role= line.
    conf = tmp_path / "cfn-hup.conf"
    conf.write_text("[main]\nregion=us-east-1\n", encoding="utf-8")
    result = ImdsRoleMatchesCfnHupConfig(cfn_hup_conf_path=str(conf)).run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert _codes(result) == [ImdsRoleMatchesCfnHupConfig.NO_ROLE_CONFIGURED.code]
    assert "No 'role' is set" in _messages(result)


def test_reads_role_when_other_values_contain_percent(monkeypatch, tmp_path):
    # A url-encoded value elsewhere in the file must not break reading role (no % interpolation).
    monkeypatch.setattr(instance_profile.imds, "get_iam_role_name", lambda: "my-instance-role")
    conf = tmp_path / "cfn-hup.conf"
    conf.write_text(
        "[main]\nstack=arn%3Aaws%3Acloudformation\nrole=my-instance-role\n",
        encoding="utf-8",
    )

    result = ImdsRoleMatchesCfnHupConfig(cfn_hup_conf_path=str(conf)).run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED


def test_run_raises_when_config_file_missing(monkeypatch, tmp_path):
    # A missing cfn-hup.conf raises; the Runner maps it to a CHECK_ERROR result.
    monkeypatch.setattr(instance_profile.imds, "get_iam_role_name", lambda: "my-instance-role")

    check = ImdsRoleMatchesCfnHupConfig(cfn_hup_conf_path=str(tmp_path / "absent.conf"))
    with pytest.raises(FileNotFoundError):
        check.run(sample_context(NodeType.HEAD))
