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

"""Unit tests for the reserved users/groups check (existence and id uniqueness)."""

import pytest

from pcluster_diag.checks import reserved_users
from pcluster_diag.checks.reserved_users import ReservedUsersAndGroups
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context

# The reserved ids ParallelCluster assigns (mirrors constants; kept explicit so a constants change is caught).
_EXPECTED_UIDS = {"pcluster-admin": 400, "slurm": 401, "munge": 402}
_EXPECTED_GIDS = {"pcluster-admin": 400, "slurm": 401, "munge": 402, "pcluster-slurm-share": 405}


def _fake_users(monkeypatch, *, uids=None, gids=None, uid_owners=None, gid_owners=None):
    """Patch the ``users`` module the check calls.

    uids/gids: name -> id (None means the user/group does not exist).
    uid_owners/gid_owners: id -> [names]; defaults to the single expected owner per id.
    """
    uids = _EXPECTED_UIDS if uids is None else uids
    gids = _EXPECTED_GIDS if gids is None else gids
    monkeypatch.setattr(reserved_users.users, "get_user_uid", lambda name: uids.get(name))
    monkeypatch.setattr(reserved_users.users, "get_group_gid", lambda name: gids.get(name))

    def usernames_for_uid(uid):
        if uid_owners is not None:
            return uid_owners.get(uid, [])
        return [name for name, value in uids.items() if value == uid]

    def groupnames_for_gid(gid):
        if gid_owners is not None:
            return gid_owners.get(gid, [])
        return [name for name, value in gids.items() if value == gid]

    monkeypatch.setattr(reserved_users.users, "get_usernames_for_uid", usernames_for_uid)
    monkeypatch.setattr(reserved_users.users, "get_groupnames_for_gid", groupnames_for_gid)


def _codes(result):
    """Return the list of error codes carried by a Result (empty list when it has no errors)."""
    return [error.code for error in (result.errors or [])]


def _messages(result):
    """Return the joined error messages carried by a Result."""
    return " | ".join(error.message for error in (result.errors or []))


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_applies_to_every_node_type(node_type):
    # Reserved users/groups exist on every node type, so the check always applies.
    assert ReservedUsersAndGroups().should_run(sample_context(node_type)) is True
    assert ReservedUsersAndGroups().approval_required(sample_context(node_type)) is False


def test_passes_when_all_present_and_unique(monkeypatch):
    _fake_users(monkeypatch)

    result = ReservedUsersAndGroups().run(sample_context())

    assert result.status is Status.PASSED
    assert result.errors is None


def test_fails_when_a_user_is_missing(monkeypatch):
    _fake_users(monkeypatch, uids={"pcluster-admin": 400, "slurm": None, "munge": 402})

    result = ReservedUsersAndGroups().run(sample_context())

    assert result.status is Status.FAILURE
    assert _codes(result) == [ReservedUsersAndGroups.MISSING.code]
    assert "user 'slurm' does not exist" in _messages(result)


def test_fails_when_a_group_is_missing(monkeypatch):
    _fake_users(
        monkeypatch,
        gids={"pcluster-admin": 400, "slurm": 401, "munge": 402, "pcluster-slurm-share": None},
    )

    result = ReservedUsersAndGroups().run(sample_context())

    assert result.status is Status.FAILURE
    assert _codes(result) == [ReservedUsersAndGroups.MISSING.code]
    assert "group 'pcluster-slurm-share' does not exist" in _messages(result)


def test_fails_when_user_uid_is_shared(monkeypatch):
    # pcluster-admin (uid 400) collides with a pre-existing account that comes first in /etc/passwd.
    _fake_users(
        monkeypatch,
        uid_owners={400: ["svc-erd", "pcluster-admin"], 401: ["slurm"], 402: ["munge"]},
    )

    result = ReservedUsersAndGroups().run(sample_context())

    assert result.status is Status.FAILURE
    assert _codes(result) == [ReservedUsersAndGroups.SHARED_ID.code]
    assert "user 'pcluster-admin' shares id 400 with: svc-erd" in _messages(result)


def test_fails_when_group_gid_is_shared(monkeypatch):
    _fake_users(
        monkeypatch,
        gid_owners={
            400: ["pcluster-admin", "legacy-grp"],
            401: ["slurm"],
            402: ["munge"],
            405: ["pcluster-slurm-share"],
        },
    )

    result = ReservedUsersAndGroups().run(sample_context())

    assert result.status is Status.FAILURE
    assert _codes(result) == [ReservedUsersAndGroups.SHARED_ID.code]
    assert "group 'pcluster-admin' shares id 400 with: legacy-grp" in _messages(result)


def test_reports_both_missing_and_shared_across_users_and_groups(monkeypatch):
    # A missing user and a shared group gid surface as two distinct errors in one run.
    _fake_users(
        monkeypatch,
        uids={"pcluster-admin": 400, "slurm": None, "munge": 402},
        gid_owners={
            400: ["pcluster-admin", "legacy-grp"],
            401: ["slurm"],
            402: ["munge"],
            405: ["pcluster-slurm-share"],
        },
    )

    result = ReservedUsersAndGroups().run(sample_context())

    assert result.status is Status.FAILURE
    assert sorted(_codes(result)) == [ReservedUsersAndGroups.MISSING.code, ReservedUsersAndGroups.SHARED_ID.code]
