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

"""Unit tests for reading the configuration files of the node."""

import pytest

from pcluster_diag.util import config_files
from pcluster_diag.util.config_files import ConfigFile, read_config_files, redact_secrets, render
from tests.stubs import stub_raising


@pytest.mark.parametrize(
    "text, expected",
    [
        pytest.param("ldap_default_authtok = s3cr3t\n", "ldap_default_authtok = <redacted>\n", id="sssd"),
        pytest.param("StoragePass=s3cr3t\n", "StoragePass=<redacted>\n", id="slurmdbd"),
        pytest.param("  db_password: s3cr3t\n", "  db_password: <redacted>\n", id="colon and indent"),
        pytest.param("API_TOKEN=abc def\n", "API_TOKEN=<redacted>\n", id="whole value"),
        pytest.param("ClientSecret = x\n", "ClientSecret = <redacted>\n", id="secret"),
    ],
)
def test_redact_secrets_replaces_the_values_of_secret_settings(text, expected):
    assert redact_secrets(text) == expected


@pytest.mark.parametrize(
    "text",
    [
        pytest.param("AuthType=auth/munge\n", id="key not naming a secret"),
        pytest.param("ldap_uri = ldaps://pass.example.com\n", id="secret word in the value"),
        pytest.param("# set StoragePass in slurmdbd.conf\n", id="comment"),
        pytest.param("StoragePass=\n", id="empty value"),
        pytest.param("cache_credentials = True\n", id="sssd credentials caching"),
        pytest.param("offline_credentials_expiration = 0\n", id="sssd credentials expiration"),
    ],
)
def test_redact_secrets_keeps_other_lines(text):
    assert redact_secrets(text) == text


def test_redact_secrets_keeps_the_lines_around_a_secret():
    text = "[domain/default]\nldap_default_authtok = s3cr3t\nldap_uri = ldaps://ad.example.com\n"

    assert redact_secrets(text) == (
        "[domain/default]\nldap_default_authtok = <redacted>\nldap_uri = ldaps://ad.example.com\n"
    )


def test_read_config_files_follows_pattern_order_and_sorts_within_a_pattern(tmp_path):
    (tmp_path / "slurm").mkdir()
    for name in ("slurm/b.conf", "slurm/a.conf", "fstab"):
        (tmp_path / name).write_text(name + "\n")
    (tmp_path / "slurm" / "dir.conf").mkdir()

    files = read_config_files([str(tmp_path / "fstab"), str(tmp_path / "missing"), str(tmp_path / "slurm" / "*.conf")])

    assert [config_file.path for config_file in files] == [
        str(tmp_path / "fstab"),
        str(tmp_path / "slurm" / "a.conf"),
        str(tmp_path / "slurm" / "b.conf"),
    ]
    assert files[1].content == "slurm/a.conf\n"


def test_read_config_files_returns_a_file_matched_twice_once(tmp_path):
    (tmp_path / "a.conf").write_text("a\n")

    files = read_config_files([str(tmp_path / "a.conf"), str(tmp_path / "*.conf")])

    assert files == [ConfigFile(str(tmp_path / "a.conf"), content="a\n")]


def test_read_config_files_redacts_secrets(tmp_path):
    (tmp_path / "slurmdbd.conf").write_text("StoragePass=s3cr3t\n")

    files = read_config_files([str(tmp_path / "slurmdbd.conf")])

    assert files[0].content == "StoragePass=<redacted>\n"


def test_read_config_files_returns_the_error_of_an_unreadable_file(tmp_path, monkeypatch):
    (tmp_path / "sssd.conf").write_text("x\n")
    monkeypatch.setattr(config_files, "open", stub_raising(PermissionError("Permission denied")), raising=False)

    files = read_config_files([str(tmp_path / "sssd.conf")])

    assert files == [ConfigFile(str(tmp_path / "sssd.conf"), error="Permission denied")]


def test_render_writes_each_file_after_a_header():
    files = [
        ConfigFile("/etc/fstab", content="UUID=1 / xfs defaults 0 0\n"),
        ConfigFile("/etc/exports", content="/home 10.0.0.0/16(rw)"),
        ConfigFile("/etc/sssd/sssd.conf", error="Permission denied"),
    ]

    assert render(files) == (
        "==> /etc/fstab <==\nUUID=1 / xfs defaults 0 0\n\n"
        "==> /etc/exports <==\n/home 10.0.0.0/16(rw)\n\n"
        "==> /etc/sssd/sssd.conf <==\n<could not read: Permission denied>\n"
    )
