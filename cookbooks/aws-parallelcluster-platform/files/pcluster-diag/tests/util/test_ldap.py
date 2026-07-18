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

"""Unit tests for the read-only LDAP/TLS probe helpers."""

import subprocess

import pytest

from pcluster_diag.util import ldap


class _FakeCompleted:
    def __init__(self, returncode=0, stdout="", stderr=""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


def test_parse_tls_verify_code_extracts_code():
    assert ldap.parse_tls_verify_code("...\nVerify return code: 0 (ok)\n...") == 0
    assert ldap.parse_tls_verify_code("Verify return code: 21 (unable to verify)") == 21


def test_parse_tls_verify_code_none_when_absent():
    assert ldap.parse_tls_verify_code("no code here") is None


# A real Amazon Linux 2023 (OpenSSL 3.x) bad-certificate output: the trailing "Verify return code" is a
# misleading 0; the true failure is in the "verify error" / "Verification error" lines.
_AL2023_BAD = (
    "CONNECTED(00000003)\n"
    "depth=0 CN=microsoftad.example.pcluster\n"
    "verify error:num=18:self-signed certificate\n"
    "Verification error: self-signed certificate\n"
    "Verify return code: 0 (ok)\n"
)

_GOOD = "depth=1 CN=corp-CA\nverify return:1\ndepth=0 CN=ad\nverify return:1\nVerify return code: 0 (ok)\n"
_UBUNTU_BAD = "depth=0 CN=ad\nverify error:num=18:self-signed certificate\nVerify return code: 18 (self-signed)\n"
_CONNECT_REFUSED = "connect:errno=111\nconnect:Connection refused\n"


@pytest.mark.parametrize(
    "output, expected",
    [
        (_AL2023_BAD, False),  # must not be fooled by trailing "Verify return code: 0 (ok)"
        (_UBUNTU_BAD, False),
        # Only a non-zero summary code, no 'verify error' line: fall back to the code.
        ("depth=0 CN=ad\nVerify return code: 20 (unable to get local issuer certificate)\n", False),
        (_GOOD, True),
        (_CONNECT_REFUSED, None),  # no certificate evaluated -> indeterminate (reachability)
        ("", None),
    ],
    ids=["al2023-bad", "ubuntu-bad", "code-only-bad", "valid", "connection-refused", "empty"],
)
def test_parse_tls_verification(output, expected):
    assert ldap.parse_tls_verification(output) is expected


def test_tls_verify_error_reason_prefers_verification_error_line():
    assert ldap.tls_verify_error_reason(_AL2023_BAD) == "self-signed certificate"


def test_tls_verify_error_reason_falls_back_to_verify_error_num():
    output = "depth=0 CN=ad\nverify error:num=18:self-signed certificate\n"
    assert ldap.tls_verify_error_reason(output) == "self-signed certificate (num 18)"


def test_tls_verify_error_reason_generic_when_unparseable():
    assert ldap.tls_verify_error_reason("something went wrong") == "certificate verification failed"


def test_verify_tls_certificate_builds_expected_argv(monkeypatch):
    captured = {}

    def fake_run(argv, **kwargs):
        captured["argv"] = argv
        captured["stdin"] = kwargs.get("stdin")
        return _FakeCompleted(0, "Verify return code: 0 (ok)")

    monkeypatch.setattr(ldap.subprocess, "run", fake_run)

    result = ldap.verify_tls_certificate("ad.example.com", 636, cafile="/etc/ca.pem")

    assert result.succeeded is True
    assert captured["argv"] == [
        "openssl",
        "s_client",
        "-connect",
        "ad.example.com:636",
        "-servername",
        "ad.example.com",
        "-verify_return_error",
        "-CAfile",
        "/etc/ca.pem",
    ]
    # stdin is closed so openssl never blocks waiting for input.
    assert captured["stdin"] is subprocess.DEVNULL


def test_verify_tls_certificate_timeout_is_data(monkeypatch):
    # partial output arrives as bytes, stderr as str: both are normalized to text.
    def fake_run(argv, **kwargs):
        raise subprocess.TimeoutExpired(argv, 30, output=b"partial", stderr="stderr-text")

    monkeypatch.setattr(ldap.subprocess, "run", fake_run)

    result = ldap.verify_tls_certificate("ad.example.com", 636)

    assert result.timed_out is True
    assert result.returncode is None
    assert result.succeeded is False
    assert result.stdout == "partial"
    assert result.stderr == "stderr-text"


def test_as_text_defaults_none_to_empty_string():
    assert ldap._as_text(None) == ""


def test_ldap_bind_search_passes_password_via_file_not_argv(monkeypatch, tmp_path):
    captured = {}
    seen_password_file = {}

    def fake_run(argv, env=None, **kwargs):
        captured["argv"] = argv
        captured["env"] = env
        # The -y file must exist at call time and contain the password (never in argv).
        path = argv[argv.index("-y") + 1]
        with open(path, encoding="utf-8") as handle:
            seen_password_file["contents"] = handle.read()
        seen_password_file["path"] = path
        return _FakeCompleted(0, "dn: DC=corp,DC=com")

    monkeypatch.setattr(ldap.subprocess, "run", fake_run)

    result = ldap.ldap_bind_search(
        "ldaps://ad.example.com",
        "CN=svc,DC=corp,DC=com",
        "s3cret",
        base="",
        attributes=["1.1"],
        cacert="/etc/ca.pem",
        reqcert="demand",
    )

    assert result.succeeded is True
    # The password appears only in the temp file, never in the argument list.
    assert "s3cret" not in captured["argv"]
    assert seen_password_file["contents"] == "s3cret"
    # TLS trust is passed via the environment, not argv.
    assert captured["env"]["LDAPTLS_CACERT"] == "/etc/ca.pem"
    assert captured["env"]["LDAPTLS_REQCERT"] == "demand"
    assert "-D" in captured["argv"] and "CN=svc,DC=corp,DC=com" in captured["argv"]
    assert "1.1" in captured["argv"]


def test_ldap_bind_search_removes_password_file_afterwards(monkeypatch):
    seen = {}

    def fake_run(argv, env=None, **kwargs):
        seen["path"] = argv[argv.index("-y") + 1]
        return _FakeCompleted(0)

    monkeypatch.setattr(ldap.subprocess, "run", fake_run)

    ldap.ldap_bind_search("ldaps://ad.example.com", "CN=svc", "pw", base="")

    import os

    assert not os.path.exists(seen["path"])


def test_ldap_bind_search_removes_password_file_on_error(monkeypatch):
    seen = {}

    def fake_run(argv, env=None, **kwargs):
        seen["path"] = argv[argv.index("-y") + 1]
        raise FileNotFoundError("ldapsearch")

    monkeypatch.setattr(ldap.subprocess, "run", fake_run)

    with pytest.raises(FileNotFoundError):
        ldap.ldap_bind_search("ldaps://ad.example.com", "CN=svc", "pw", base="")

    import os

    assert not os.path.exists(seen["path"])
