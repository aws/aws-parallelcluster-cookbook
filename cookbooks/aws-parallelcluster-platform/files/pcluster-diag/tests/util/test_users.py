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

"""Unit tests for the POSIX user/group database helpers."""

import grp
import pwd

from pcluster_diag.util import users


def _passwd(name, uid, gid=0):
    """Build a pwd.struct_passwd-like record with the fields the helpers read."""
    return pwd.struct_passwd((name, "x", uid, gid, "", "/home/{}".format(name), "/bin/bash"))


def _group(name, gid):
    """Build a grp.struct_group-like record with the fields the helpers read."""
    return grp.struct_group((name, "x", gid, []))


def test_get_user_uid_and_gid_return_values_for_existing_user(monkeypatch):
    monkeypatch.setattr(users.pwd, "getpwnam", lambda name: _passwd("pcluster-admin", 400, 400))

    assert users.get_user_uid("pcluster-admin") == 400
    assert users.get_user_gid("pcluster-admin") == 400


def test_get_user_uid_and_gid_return_none_for_missing_user(monkeypatch):
    def _raise(_name):
        raise KeyError("no such user")

    monkeypatch.setattr(users.pwd, "getpwnam", _raise)

    assert users.get_user_uid("ghost") is None
    assert users.get_user_gid("ghost") is None


def test_get_group_gid_returns_value_and_none(monkeypatch):
    monkeypatch.setattr(users.grp, "getgrnam", lambda name: _group("pcluster-slurm-share", 405))
    assert users.get_group_gid("pcluster-slurm-share") == 405

    def _raise(_name):
        raise KeyError("no such group")

    monkeypatch.setattr(users.grp, "getgrnam", _raise)
    assert users.get_group_gid("ghost") is None


def test_get_username_for_uid_returns_name_or_numeric_fallback(monkeypatch):
    monkeypatch.setattr(users.pwd, "getpwuid", lambda uid: _passwd("pcluster-admin", uid, uid))
    assert users.get_username_for_uid(400) == "pcluster-admin"

    def _raise(_uid):
        raise KeyError("no such uid")

    monkeypatch.setattr(users.pwd, "getpwuid", _raise)
    # With no /etc/passwd entry, the numeric uid is returned as a string.
    assert users.get_username_for_uid(1234) == "1234"


def test_get_groupname_for_gid_returns_name_or_numeric_fallback(monkeypatch):
    monkeypatch.setattr(users.grp, "getgrgid", lambda gid: _group("pcluster-admin", gid))
    assert users.get_groupname_for_gid(400) == "pcluster-admin"

    def _raise(_gid):
        raise KeyError("no such gid")

    monkeypatch.setattr(users.grp, "getgrgid", _raise)
    # With no /etc/group entry, the numeric gid is returned as a string.
    assert users.get_groupname_for_gid(1234) == "1234"


def test_get_usernames_for_uid_returns_every_matching_name_in_order(monkeypatch):
    # svc-erd is listed before pcluster-admin, both sharing uid 400.
    database = [_passwd("root", 0), _passwd("svc-erd", 400), _passwd("pcluster-admin", 400), _passwd("slurm", 401)]
    monkeypatch.setattr(users.pwd, "getpwall", lambda: database)

    assert users.get_usernames_for_uid(400) == ["svc-erd", "pcluster-admin"]
    assert users.get_usernames_for_uid(401) == ["slurm"]
    assert users.get_usernames_for_uid(999) == []


def test_get_groupnames_for_gid_returns_every_matching_name_in_order(monkeypatch):
    database = [_group("root", 0), _group("pcluster-admin", 400), _group("legacy", 400)]
    monkeypatch.setattr(users.grp, "getgrall", lambda: database)

    assert users.get_groupnames_for_gid(400) == ["pcluster-admin", "legacy"]
    assert users.get_groupnames_for_gid(0) == ["root"]
    assert users.get_groupnames_for_gid(999) == []
