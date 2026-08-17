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

"""Unit tests for the IMDS check covering responsiveness, instance tags, and per-user access."""

import pytest

from pcluster_diag.checks import imds as imds_check
from pcluster_diag.checks.imds import Imds
from pcluster_diag.core.constants import CLUSTER_ADMIN_USER, ROOT_USER, SLURM_USER
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.util import imds
from tests.sample_data import sample_context

_ALL_USERS = {ROOT_USER, CLUSTER_ADMIN_USER, SLURM_USER}
_PRIVILEGED_USERS = {ROOT_USER, CLUSTER_ADMIN_USER}


def _context(imds_support=None, secured=None, node_type=NodeType.HEAD):
    """Return a sample Context whose cluster config carries the given ImdsSupport and Secured values."""
    context = sample_context(node_type)
    config = {}
    if imds_support:
        config["Imds"] = {"ImdsSupport": imds_support}
    if secured is not None:
        config["HeadNode"] = {"Imds": {"Secured": secured}}
    context.cluster_config = config
    return context


def _patch_functional(monkeypatch, list_metadata=None, get_instance_tags=None):
    """Patch the IMDS functional probes with the given fakes (defaulting to successful responses)."""
    monkeypatch.setattr(imds_check.imds, "list_metadata", list_metadata or (lambda _version: "instance-id\ntags/"))
    monkeypatch.setattr(
        imds_check.imds, "get_instance_tags", get_instance_tags or (lambda _version: "aws:parallelcluster:node-type")
    )


def _patch_access(monkeypatch, responsive_users):
    """Patch the per-user IMDS probe so only ``responsive_users`` are reported reachable."""
    monkeypatch.setattr(imds_check.imds, "is_responsive_for_user", lambda user: user in responsive_users)


@pytest.fixture(autouse=True)
def _imds_reports_role(monkeypatch):
    """Make IMDS report an IAM role by default so tests can focus on the other IMDS behavior.

    Tests that exercise the missing-role case override this with ``get_iam_role_name`` returning None.
    """
    monkeypatch.setattr(imds_check.imds, "get_iam_role_name", lambda: "my-instance-role")


def test_description():
    assert Imds().description == "Verify that IMDS is responsive and functional."


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_should_run(node_type):
    # IMDS exists on every instance, so the check applies to every node type.
    assert Imds().should_run(sample_context(node_type)) is True


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_approval_required(node_type):
    assert Imds().approval_required(sample_context(node_type)) is False


@pytest.mark.parametrize(
    "imds_support, expected_version",
    [
        ("v2.0", imds.IMDS_V2),
        ("v1.0", imds.IMDS_V1),
        (None, imds.IMDS_V2),  # unset in the config defaults to IMDSv2
    ],
)
def test_run_passes_using_configured_version(monkeypatch, imds_support, expected_version):
    used_versions = []

    def fake_list_metadata(version):
        used_versions.append(version)
        return "instance-id\ntags/"

    def fake_get_instance_tags(version):
        used_versions.append(version)
        return "aws:parallelcluster:node-type"

    _patch_functional(monkeypatch, fake_list_metadata, fake_get_instance_tags)
    _patch_access(monkeypatch, _PRIVILEGED_USERS)

    result = Imds().run(_context(imds_support=imds_support, secured=True))

    assert result.status is Status.PASSED
    assert result.errors is None
    # Both probes must exercise the version enabled in the cluster configuration.
    assert used_versions == [expected_version, expected_version]


def test_run_fails_when_imds_not_responsive(monkeypatch):
    def _raise(_version):
        raise OSError("connection refused")

    monkeypatch.setattr(imds_check.imds, "list_metadata", _raise)
    _patch_access(monkeypatch, _PRIVILEGED_USERS)

    result = Imds().run(_context(imds_support="v2.0", secured=True))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [Imds.NOT_RESPONSIVE.code]


def test_run_warns_when_tags_metadata_not_reachable(monkeypatch):
    # An unreachable instance tags resource is only a warning, so the check is still successful.
    def _raise(_version):
        raise OSError("HTTP Error 404: Not Found")

    _patch_functional(monkeypatch, get_instance_tags=_raise)
    _patch_access(monkeypatch, _PRIVILEGED_USERS)

    result = Imds().run(_context(imds_support="v1.0", secured=True))

    assert result.status is Status.WARNING
    assert result.errors is None
    assert [warning.code for warning in result.warnings] == [Imds.TAGS_NOT_AVAILABLE.code]


def test_run_failure_still_carries_tags_warning(monkeypatch):
    # A per-user access failure and an unreachable tags resource surface together: FAILURE, but the
    # tags warning is preserved alongside the errors.
    def _raise(_version):
        raise OSError("HTTP Error 404: Not Found")

    _patch_functional(monkeypatch, get_instance_tags=_raise)
    _patch_access(monkeypatch, _ALL_USERS)

    result = Imds().run(_context(secured=True, node_type=NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [Imds.UNEXPECTEDLY_ALLOWED.code]
    assert [warning.code for warning in result.warnings] == [Imds.TAGS_NOT_AVAILABLE.code]


@pytest.mark.parametrize(
    "secured, node_type, responsive_users",
    [
        # Secured on head/login: privileged users reachable, unprivileged denied.
        (True, NodeType.HEAD, _PRIVILEGED_USERS),
        (True, NodeType.LOGIN, _PRIVILEGED_USERS),
        # Secured but on a compute node: the lockdown does not apply, so all users are reachable.
        (True, NodeType.COMPUTE, _ALL_USERS),
        # Secured disabled: all users reachable on every node type.
        (False, NodeType.HEAD, _ALL_USERS),
        (False, NodeType.LOGIN, _ALL_USERS),
        (False, NodeType.COMPUTE, _ALL_USERS),
        # Secured unset defaults to enabled, so head/login lock out the unprivileged user.
        (None, NodeType.HEAD, _PRIVILEGED_USERS),
    ],
)
def test_run_passes_when_access_matches_expectation(monkeypatch, secured, node_type, responsive_users):
    _patch_functional(monkeypatch)
    _patch_access(monkeypatch, responsive_users)

    result = Imds().run(_context(secured=secured, node_type=node_type))

    assert result.status is Status.PASSED
    assert result.errors is None


def test_run_fails_when_unprivileged_user_not_denied_under_lockdown(monkeypatch):
    # Secured head node, but the unprivileged user can still reach IMDS: the lockdown is not effective.
    _patch_functional(monkeypatch)
    _patch_access(monkeypatch, _ALL_USERS)

    result = Imds().run(_context(secured=True, node_type=NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [Imds.UNEXPECTEDLY_ALLOWED.code]
    assert SLURM_USER in result.errors[0].message


def test_run_fails_when_privileged_user_denied(monkeypatch):
    # The cluster admin cannot reach IMDS even though it always should.
    _patch_functional(monkeypatch)
    _patch_access(monkeypatch, {ROOT_USER})

    result = Imds().run(_context(secured=False, node_type=NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    # The admin is wrongly denied; the unprivileged user is also expected reachable here and is denied too.
    codes = [error.code for error in result.errors]
    assert codes == [Imds.UNEXPECTEDLY_DENIED.code, Imds.UNEXPECTEDLY_DENIED.code]


def test_run_reports_both_functional_and_access_errors(monkeypatch):
    # A non-responsive IMDS and a broken lockdown surface together in a single result.
    def _raise(_version):
        raise OSError("connection refused")

    monkeypatch.setattr(imds_check.imds, "list_metadata", _raise)
    _patch_access(monkeypatch, _ALL_USERS)

    result = Imds().run(_context(secured=True, node_type=NodeType.HEAD))

    assert result.status is Status.FAILURE
    codes = [error.code for error in result.errors]
    assert codes == [Imds.NOT_RESPONSIVE.code, Imds.UNEXPECTEDLY_ALLOWED.code]


def test_run_fails_when_imds_reports_no_role(monkeypatch):
    # A responsive IMDS that exposes no IAM role for the instance is a functional failure.
    _patch_functional(monkeypatch)
    _patch_access(monkeypatch, _PRIVILEGED_USERS)
    monkeypatch.setattr(imds_check.imds, "get_iam_role_name", lambda: None)

    result = Imds().run(_context(secured=True, node_type=NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [Imds.NO_ROLE_FROM_IMDS.code]


def test_run_reports_missing_iam_role_on_any_responsive_node(monkeypatch):
    # Every cluster node has an instance role, so the role check is not limited to the head node.
    _patch_functional(monkeypatch)
    _patch_access(monkeypatch, _ALL_USERS)  # secured=False so every user is reachable: no access error
    monkeypatch.setattr(imds_check.imds, "get_iam_role_name", lambda: None)

    result = Imds().run(_context(secured=False, node_type=NodeType.COMPUTE))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [Imds.NO_ROLE_FROM_IMDS.code]


def test_run_skips_iam_role_check_when_imds_not_responsive(monkeypatch):
    # The role probe only runs once IMDS responds, so an unresponsive IMDS reports NOT_RESPONSIVE alone.
    def _raise(_version):
        raise OSError("connection refused")

    monkeypatch.setattr(imds_check.imds, "list_metadata", _raise)
    _patch_access(monkeypatch, _PRIVILEGED_USERS)
    monkeypatch.setattr(imds_check.imds, "get_iam_role_name", lambda: None)

    result = Imds().run(_context(secured=True, node_type=NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [Imds.NOT_RESPONSIVE.code]
