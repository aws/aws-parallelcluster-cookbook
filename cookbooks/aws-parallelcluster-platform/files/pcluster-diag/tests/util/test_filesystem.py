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

"""Unit tests for the filesystem ownership/permission helpers."""

import os

import pytest

from pcluster_diag.util import filesystem


def test_stat_path_reports_owner_group_and_octal_mode(tmp_path, monkeypatch):
    target = tmp_path / "computefleet-status.json"
    target.write_text("{}", encoding="utf-8")
    os.chmod(target, 0o700)

    monkeypatch.setattr(filesystem.users, "get_username_for_uid", lambda uid: "pcluster-admin")
    monkeypatch.setattr(filesystem.users, "get_groupname_for_gid", lambda gid: "pcluster-admin")

    result = filesystem.stat_path(str(target))

    assert result.owner == "pcluster-admin"
    assert result.group == "pcluster-admin"
    assert result.mode == "0700"


def test_stat_path_passes_the_paths_uid_and_gid_to_the_name_lookups(tmp_path, monkeypatch):
    target = tmp_path / "file"
    target.write_text("x", encoding="utf-8")
    seen = {}

    def fake_username(uid):
        seen["uid"] = uid
        return "u"

    def fake_groupname(gid):
        seen["gid"] = gid
        return "g"

    monkeypatch.setattr(filesystem.users, "get_username_for_uid", fake_username)
    monkeypatch.setattr(filesystem.users, "get_groupname_for_gid", fake_groupname)

    filesystem.stat_path(str(target))

    assert seen["uid"] == target.stat().st_uid
    assert seen["gid"] == target.stat().st_gid


def test_stat_path_reports_mode_as_four_digit_octal(tmp_path, monkeypatch):
    target = tmp_path / "file"
    target.write_text("x", encoding="utf-8")
    os.chmod(target, 0o600)
    monkeypatch.setattr(filesystem.users, "get_username_for_uid", lambda uid: "u")
    monkeypatch.setattr(filesystem.users, "get_groupname_for_gid", lambda gid: "g")

    assert filesystem.stat_path(str(target)).mode == "0600"


def test_stat_path_raises_for_missing_path(tmp_path):
    with pytest.raises(FileNotFoundError):
        filesystem.stat_path(str(tmp_path / "does-not-exist"))
