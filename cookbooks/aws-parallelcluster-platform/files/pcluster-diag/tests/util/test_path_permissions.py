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

"""Unit tests for the path ownership/permission helpers."""

import os

import pytest

from pcluster_diag.util import path_permissions
from pcluster_diag.util.path_permissions import describe_bits, format_bits, parse_mode


def test_stat_path_reports_owner_group_and_octal_mode(tmp_path, monkeypatch):
    target = tmp_path / "computefleet-status.json"
    target.write_text("{}", encoding="utf-8")
    os.chmod(target, 0o700)

    monkeypatch.setattr(path_permissions.users, "get_username_for_uid", lambda uid: "pcluster-admin")
    monkeypatch.setattr(path_permissions.users, "get_groupname_for_gid", lambda gid: "pcluster-admin")

    result = path_permissions.stat_path(str(target))

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

    monkeypatch.setattr(path_permissions.users, "get_username_for_uid", fake_username)
    monkeypatch.setattr(path_permissions.users, "get_groupname_for_gid", fake_groupname)

    path_permissions.stat_path(str(target))

    assert seen["uid"] == target.stat().st_uid
    assert seen["gid"] == target.stat().st_gid


def test_stat_path_reports_mode_as_four_digit_octal(tmp_path, monkeypatch):
    target = tmp_path / "file"
    target.write_text("x", encoding="utf-8")
    os.chmod(target, 0o600)
    monkeypatch.setattr(path_permissions.users, "get_username_for_uid", lambda uid: "u")
    monkeypatch.setattr(path_permissions.users, "get_groupname_for_gid", lambda gid: "g")

    assert path_permissions.stat_path(str(target)).mode == "0600"


def test_stat_path_raises_for_missing_path(tmp_path):
    with pytest.raises(FileNotFoundError):
        path_permissions.stat_path(str(tmp_path / "does-not-exist"))


@pytest.mark.parametrize("mode, expected", [("0640", 0o640), ("0600", 0o600), ("4755", 0o4755)])
def test_parse_mode(mode, expected):
    assert parse_mode(mode) == expected


@pytest.mark.parametrize("bits, expected", [(0o640, "0640"), (0o2, "0002"), (0, "0000")])
def test_format_bits(bits, expected):
    assert format_bits(bits) == expected


@pytest.mark.parametrize(
    "bits, expected",
    [
        (0o100, "owner execute/traverse"),
        (0o400, "owner read"),
        (0o022, "group write, other write"),
        (0o040, "group read"),
        (0, ""),
    ],
)
def test_describe_bits(bits, expected):
    assert describe_bits(bits) == expected
