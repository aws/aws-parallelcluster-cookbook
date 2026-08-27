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

"""Unit tests for the Slurm accounting util: config resolution, secret handling, redaction, mysql probe."""

import os

import pytest
from botocore.exceptions import ClientError
from hypothesis import given
from hypothesis import strategies as st

from pcluster_diag.core.constants import DEFAULT_DATABASE_PORT, DEFAULT_SLURMDBD_PORT, SCONTROL_PATH
from pcluster_diag.models.context import NodeType
from pcluster_diag.util import slurm_accounting as acct
from tests.sample_data import sample_context


class _FakeCompleted:
    """A minimal stand-in for ``subprocess.CompletedProcess``."""

    def __init__(self, returncode=0, stdout="", stderr=""):
        self.returncode = returncode
        self.stdout = stdout
        self.stderr = stderr


@pytest.fixture(autouse=True)
def _scontrol_unavailable_by_default(monkeypatch):
    """Simulate scontrol being absent by default so config resolution is hermetic.

    Functions that read the effective Slurm config shell out to ``scontrol show config``; without this
    the tests would depend on whether scontrol happens to exist on the host. Tests that exercise a
    specific scontrol output override ``shell.run_command`` themselves.
    """

    def _missing(argv, timeout=None):
        raise FileNotFoundError("scontrol")

    monkeypatch.setattr(acct.shell, "run_command", _missing)


def _stub_scontrol(monkeypatch, stdout, returncode=0, stderr=""):
    """Make ``scontrol show config`` return the given output."""
    monkeypatch.setattr(
        acct.shell, "run_command", lambda argv, timeout=None: _FakeCompleted(returncode, stdout, stderr)
    )


def _context_with_slurm_settings(slurm_settings):
    context = sample_context(NodeType.HEAD)
    context.cluster_config["Scheduling"] = {"SlurmSettings": slurm_settings}
    return context


# --- parse_keyvalue_conf --------------------------------------------------------------


def test_parse_keyvalue_conf_reads_pairs_and_strips_comments(tmp_path):
    conf = tmp_path / "slurmdbd.conf"
    conf.write_text(
        "# a comment\n"
        "StorageHost = db.example.com   # trailing comment\n"
        "\n"
        "StoragePort=3306\n"
        "no_equals_line\n"
        "StoragePass=first\n"
        "StoragePass=second\n",  # last assignment wins
        encoding="utf-8",
    )

    values = acct.parse_keyvalue_conf(str(conf))

    assert values == {
        "StorageHost": "db.example.com",
        "StoragePort": "3306",
        "StoragePass": "second",
    }


def test_parse_keyvalue_conf_raises_file_not_found_for_missing_file(tmp_path):
    with pytest.raises(FileNotFoundError):
        acct.parse_keyvalue_conf(str(tmp_path / "does-not-exist.conf"))


# --- parse_db_uri ---------------------------------------------------------------------


@pytest.mark.parametrize(
    "uri, expected",
    [
        ("db.example.com:3307", ("db.example.com", 3307)),
        ("db.example.com", ("db.example.com", None)),
        ("db.example.com:notaport", ("db.example.com", None)),
        (":3306", (None, 3306)),
        ("", (None, None)),
        (None, (None, None)),
    ],
    ids=["host-port", "host-only", "bad-port", "port-only", "empty", "none"],
)
def test_parse_db_uri(uri, expected):
    assert acct.parse_db_uri(uri) == expected


# --- resolve_accounting_config --------------------------------------------------------


def test_resolve_config_external_mode_populates_only_slurmdbd_endpoint():
    context = _context_with_slurm_settings({"ExternalSlurmdbd": {"Host": "ext.example.com", "Port": 7000}})

    config = acct.resolve_accounting_config(context)

    assert config.is_external is True
    assert (config.slurmdbd_host, config.slurmdbd_port) == ("ext.example.com", 7000)
    assert config.db_host is None and config.db_port is None
    assert config.db_user is None and config.db_name is None and config.password_secret_arn is None


def test_resolve_config_local_mode_parses_database_uri_and_defaults():
    context = _context_with_slurm_settings(
        {
            "Database": {
                "Uri": "db.example.com",  # no port -> default database port applies
                "UserName": "admin",
                "DatabaseName": "acct_db",
                "PasswordSecretArn": "arn:aws:secretsmanager:us-east-1:1:secret:pw",
            }
        }
    )

    config = acct.resolve_accounting_config(context)

    assert config.is_external is False
    assert config.slurmdbd_host == acct.LOCAL_SLURMDBD_HOST
    assert config.slurmdbd_port == DEFAULT_SLURMDBD_PORT  # slurm.conf absent -> default
    assert (config.db_host, config.db_port) == ("db.example.com", DEFAULT_DATABASE_PORT)
    assert config.db_user == "admin"
    assert config.db_name == "acct_db"


def test_resolve_config_derives_db_name_from_cluster_name_when_unset():
    context = _context_with_slurm_settings({"Database": {"Uri": "db:3306", "UserName": "admin"}})
    context.dna_json["cluster"]["cluster_name"] = "my-cluster"

    config = acct.resolve_accounting_config(context)

    assert config.db_name == "my_cluster"  # dashes replaced with underscores


# --- resolve_accounting_config: out-of-band accounting (not declared in cluster config) ----------


def test_resolve_config_out_of_band_local_derives_db_fields_from_slurmdbd_conf(monkeypatch):
    # Neither Database nor ExternalSlurmdbd in the cluster config, but slurmdbd runs locally and its
    # conf carries the database connection details -> derive the database fields from it.
    monkeypatch.setattr(
        acct,
        "read_slurmdbd_conf",
        lambda: {
            "StorageHost": "oob-db.example.com",
            "StoragePort": "3307",
            "StorageUser": "slurmacct",
            "StorageLoc": "acct_oob",
        },
    )

    config = acct.resolve_accounting_config(sample_context(NodeType.HEAD))

    assert config.is_external is False
    assert config.slurmdbd_host == acct.LOCAL_SLURMDBD_HOST
    assert (config.db_host, config.db_port) == ("oob-db.example.com", 3307)
    assert config.db_user == "slurmacct"
    assert config.db_name == "acct_oob"
    assert config.password_secret_arn is None  # out-of-band has no PasswordSecretArn


def test_resolve_config_out_of_band_local_defaults_db_port_when_absent(monkeypatch):
    monkeypatch.setattr(acct, "read_slurmdbd_conf", lambda: {"StorageHost": "oob-db", "StorageUser": "u"})

    config = acct.resolve_accounting_config(sample_context(NodeType.HEAD))

    assert config.db_port == DEFAULT_DATABASE_PORT


def test_resolve_config_out_of_band_local_db_name_falls_back_to_cluster_name(monkeypatch):
    monkeypatch.setattr(acct, "read_slurmdbd_conf", lambda: {"StorageHost": "oob-db", "StorageUser": "u"})
    context = sample_context(NodeType.HEAD)
    context.dna_json["cluster"]["cluster_name"] = "my-cluster"

    config = acct.resolve_accounting_config(context)

    assert config.db_name == "my_cluster"  # no StorageLoc -> default from cluster name


def test_resolve_config_out_of_band_external_uses_scontrol_endpoint(monkeypatch):
    # No local slurmdbd conf (slurmdbd runs on a separate instance) -> external, endpoint from scontrol.
    monkeypatch.setattr(acct, "read_slurmdbd_conf", lambda: {})
    _stub_scontrol(monkeypatch, "AccountingStorageHost = ext-dbd.example.com\nAccountingStoragePort = 6820\n")

    config = acct.resolve_accounting_config(sample_context(NodeType.HEAD))

    assert config.is_external is True
    assert (config.slurmdbd_host, config.slurmdbd_port) == ("ext-dbd.example.com", 6820)
    assert config.db_host is None and config.db_user is None and config.password_secret_arn is None


def test_resolve_config_out_of_band_external_defaults_slurmdbd_port(monkeypatch):
    monkeypatch.setattr(acct, "read_slurmdbd_conf", lambda: {})
    _stub_scontrol(monkeypatch, "AccountingStorageHost = ext-dbd.example.com\n")  # no port

    config = acct.resolve_accounting_config(sample_context(NodeType.HEAD))

    assert config.slurmdbd_port == DEFAULT_SLURMDBD_PORT


# --- read_slurmdbd_conf ---------------------------------------------------------------


def test_read_slurmdbd_conf_merges_files_with_include_overriding(monkeypatch):
    def fake_parse(path):
        if path == acct.SLURMDBD_CONF_PATH:
            return {"StorageHost": "base", "StoragePort": "3306", "StorageUser": "u"}
        if path == acct.SLURM_PARALLELCLUSTER_SLURMDBD_CONF_PATH:
            return {"StorageHost": "override"}  # PC-managed include wins for overlapping keys
        raise FileNotFoundError(path)

    monkeypatch.setattr(acct, "parse_keyvalue_conf", fake_parse)

    merged = acct.read_slurmdbd_conf()

    assert merged == {"StorageHost": "override", "StoragePort": "3306", "StorageUser": "u"}


def test_read_slurmdbd_conf_skips_absent_or_unreadable_files(monkeypatch):
    def only_base(path):
        if path == acct.SLURMDBD_CONF_PATH:
            return {"StorageHost": "base"}
        raise PermissionError(path)  # include present but unreadable

    monkeypatch.setattr(acct, "parse_keyvalue_conf", only_base)

    assert acct.read_slurmdbd_conf() == {"StorageHost": "base"}


def test_read_slurmdbd_conf_empty_when_no_files(monkeypatch):
    def missing(path):
        raise FileNotFoundError(path)

    monkeypatch.setattr(acct, "parse_keyvalue_conf", missing)

    assert acct.read_slurmdbd_conf() == {}


# --- accounting_configured ------------------------------------------------------------


def test_accounting_declared_in_config_true_for_external():
    context = _context_with_slurm_settings({"ExternalSlurmdbd": {"Host": "ext"}})
    assert acct.accounting_declared_in_config(context) is True


def test_accounting_declared_in_config_true_for_local_database():
    context = _context_with_slurm_settings({"Database": {"Uri": "db"}})
    assert acct.accounting_declared_in_config(context) is True


def test_accounting_declared_in_config_false_when_neither_declared():
    assert acct.accounting_declared_in_config(sample_context(NodeType.HEAD)) is False


# A representative slice of `scontrol show config` output (key = value, padded).
_SCONTROL_SLURMDBD = (
    "Configuration data as of 2026-07-28T00:00:00\n"
    "AccountingStorageHost   = ip-10-0-0-1\n"
    "AccountingStoragePort   = 6819\n"
    "AccountingStorageType   = accounting_storage/slurmdbd\n"
)


def test_accounting_present_on_node_true_when_scontrol_reports_slurmdbd(monkeypatch):
    _stub_scontrol(monkeypatch, _SCONTROL_SLURMDBD)
    assert acct.accounting_present_on_node() is True


def test_accounting_present_on_node_value_match_is_case_insensitive(monkeypatch):
    _stub_scontrol(monkeypatch, "AccountingStorageType = Accounting_Storage/SlurmDBD\n")
    assert acct.accounting_present_on_node() is True


def test_accounting_present_on_node_false_for_other_backend(monkeypatch):
    _stub_scontrol(monkeypatch, "AccountingStorageType = accounting_storage/none\n")
    assert acct.accounting_present_on_node() is False


def test_accounting_present_on_node_false_when_scontrol_unavailable():
    # The autouse fixture makes scontrol absent (FileNotFoundError) -> cannot determine -> False.
    assert acct.accounting_present_on_node() is False


def test_accounting_present_on_node_false_when_scontrol_errors(monkeypatch):
    _stub_scontrol(monkeypatch, stdout="", returncode=1, stderr="slurmctld is down")
    assert acct.accounting_present_on_node() is False


def test_scontrol_config_issues_expected_command_and_parses_pairs(monkeypatch):
    captured = {}

    def fake(argv, timeout=None):
        captured["argv"] = argv
        return _FakeCompleted(
            0, "Configuration data as of 2026\nSlurmUser = slurm\nAccountingStoragePort   = 6819\nnot a kv line\n"
        )

    monkeypatch.setattr(acct.shell, "run_command", fake)

    config = acct._scontrol_config()

    assert captured["argv"] == [SCONTROL_PATH, "show", "config"]
    assert config["SlurmUser"] == "slurm"
    assert config["AccountingStoragePort"] == "6819"
    assert "not a kv line" not in config  # lines without '=' are skipped


# --- get_secret_string ----------------------------------------------------------------


class _FakeSecretsClient:
    def __init__(self, *, secret_string=None, error_code=None):
        self._secret_string = secret_string
        self._error_code = error_code

    def get_secret_value(self, SecretId):  # noqa: N803 - matches boto3 kwarg
        if self._error_code:
            raise ClientError({"Error": {"Code": self._error_code}}, "GetSecretValue")
        return {"SecretString": self._secret_string}


def _patch_secrets_client(monkeypatch, client):
    monkeypatch.setattr(acct.boto3, "client", lambda service, region_name=None: client)


def test_get_secret_string_returns_plaintext(monkeypatch):
    _patch_secrets_client(monkeypatch, _FakeSecretsClient(secret_string="s3cret"))
    assert acct.get_secret_string("arn:pw", "us-east-1") == "s3cret"


@pytest.mark.parametrize("code", ["AccessDenied", "AccessDeniedException"])
def test_get_secret_string_maps_access_denied(monkeypatch, code):
    _patch_secrets_client(monkeypatch, _FakeSecretsClient(error_code=code))
    with pytest.raises(acct.SecretAccessDenied):
        acct.get_secret_string("arn:pw", "us-east-1")


def test_get_secret_string_maps_not_found(monkeypatch):
    _patch_secrets_client(monkeypatch, _FakeSecretsClient(error_code="ResourceNotFoundException"))
    with pytest.raises(acct.SecretNotFound):
        acct.get_secret_string("arn:pw", "us-east-1")


def test_get_secret_string_reraises_other_client_errors(monkeypatch):
    _patch_secrets_client(monkeypatch, _FakeSecretsClient(error_code="ThrottlingException"))
    with pytest.raises(ClientError):
        acct.get_secret_string("arn:pw", "us-east-1")


# --- secret_is_json_object ------------------------------------------------------------


@pytest.mark.parametrize(
    "secret, expected",
    [
        ('{"username": "admin", "password": "p"}', True),
        ("plaintext-password", False),
        ("12345", False),  # a bare JSON number is not an object
        ('"just-a-string"', False),
        ("not json at all {", False),
    ],
    ids=["json-object", "plaintext", "json-number", "json-string", "invalid-json"],
)
def test_secret_is_json_object(secret, expected):
    assert acct.secret_is_json_object(secret) is expected


# --- redaction ------------------------------------------------------------------------


def test_redact_replaces_every_occurrence():
    assert acct.redact("pw=hunter2 and again hunter2", "hunter2") == (
        "pw={0} and again {0}".format(acct.REDACTION_PLACEHOLDER)
    )


@pytest.mark.parametrize("secret", [None, ""])
def test_redact_no_op_when_secret_absent(secret):
    assert acct.redact("nothing to redact", secret) == "nothing to redact"


@given(text=st.text(), secret=st.text(alphabet="abcdefghijklmnopqrstuvwxyz", min_size=1))
def test_redact_never_leaves_the_secret_behind(text, secret):
    # The secret alphabet is disjoint from the placeholder, so no replacement can re-form it.
    combined = secret + text + secret
    assert secret not in acct.redact(combined, secret)


@pytest.mark.parametrize(
    "password, expected",
    [("has#hash", True), ("clean", False), (None, False), ("#", True)],
    ids=["with-hash", "clean", "none", "only-hash"],
)
def test_contains_reserved_comment_char(password, expected):
    assert acct.contains_reserved_comment_char(password) is expected


# --- mysql_probe ----------------------------------------------------------------------


def test_mysql_probe_keeps_password_out_of_argv_and_removes_temp_file(monkeypatch):
    captured = {}

    def fake_run(argv, timeout=None):
        captured["argv"] = argv
        path = argv[1].split("=", 1)[1]
        captured["defaults_path"] = path
        with open(path, encoding="utf-8") as handle:
            captured["defaults_contents"] = handle.read()
        return _FakeCompleted(returncode=0, stdout="1", stderr="")

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    result = acct.mysql_probe("db", 3306, "admin", "s3cret", database="acct_db", sql="SELECT 1", timeout=10)

    assert result.succeeded is True
    assert "s3cret" not in " ".join(captured["argv"])  # password never on the command line
    # Only in the 0600 defaults file, and quoted so reserved characters survive verbatim.
    assert 'password="s3cret"' in captured["defaults_contents"]
    assert "acct_db" in captured["argv"]  # database passed as a positional argument
    assert not os.path.exists(captured["defaults_path"])  # temp file cleaned up


@pytest.mark.parametrize(
    "password, expected",
    [
        ("plain", '"plain"'),
        ("has#hash", '"has#hash"'),  # '#' would otherwise start a comment and truncate the value
        ("has;semi", '"has;semi"'),  # ';' is also a comment character in option files
        ("back\\slash", '"back\\\\slash"'),  # a literal backslash is doubled inside a quoted value
        ('quo"te', '"quo\\"te"'),  # an embedded double quote is escaped so it does not end the value
    ],
    ids=["plain", "hash", "semicolon", "backslash", "quote"],
)
def test_quote_option_value(password, expected):
    assert acct.quote_option_value(password) == expected


def test_mysql_probe_quotes_reserved_hash_password_so_it_is_not_truncated(monkeypatch):
    """A '#' password must reach the client intact, not be truncated by the option-file parser.

    This is the very truncation the accounting checks diagnose in slurmdbd.conf, so the probe must
    not reproduce it and report a bogus 'invalid credentials' verdict for a correct password.
    """
    captured = {}

    def fake_run(argv, timeout=None):
        path = argv[1].split("=", 1)[1]
        with open(path, encoding="utf-8") as handle:
            captured["defaults_contents"] = handle.read()
        return _FakeCompleted(returncode=0)

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    acct.mysql_probe("db", 3306, "admin", "pa#ss", database=None, sql="SELECT 1", timeout=10)

    password_line = [line for line in captured["defaults_contents"].splitlines() if line.startswith("password=")][0]
    assert password_line == 'password="pa#ss"'
    # The '#' is inside the quoted value, so nothing after it is dropped as a comment.
    assert "pa#ss" in password_line


def test_mysql_probe_omits_connect_timeout_when_falsy(monkeypatch):
    captured = {}

    def fake_run(argv, timeout=None):
        captured["argv"] = argv
        return _FakeCompleted(returncode=0)

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    acct.mysql_probe("db", 3306, "admin", "pw", database=None, sql="SELECT 1", timeout=0)

    assert not any(arg.startswith("--connect-timeout") for arg in captured["argv"])


def test_mysql_probe_omits_database_positional_when_none(monkeypatch):
    captured = {}

    def fake_run(argv, timeout=None):
        captured["argv"] = argv
        return _FakeCompleted(returncode=0)

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    acct.mysql_probe("db", 3306, "admin", "pw", database=None, sql="SELECT 1", timeout=10)

    # argv tail is fixed: ... -N -B -e <sql>, with no database token before -N.
    assert captured["argv"][-4:] == ["-N", "-B", "-e", "SELECT 1"]


def test_mysql_probe_redacts_password_from_output(monkeypatch):
    def fake_run(argv, timeout=None):
        return _FakeCompleted(returncode=1, stdout="", stderr="Access denied using password s3cret")

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    result = acct.mysql_probe("db", 3306, "admin", "s3cret", database=None, sql="SELECT 1", timeout=10)

    assert "s3cret" not in result.stderr
    assert acct.REDACTION_PLACEHOLDER in result.stderr


def test_mysql_probe_reports_timeout_as_data(monkeypatch):
    import subprocess

    def fake_run(argv, timeout=None):
        raise subprocess.TimeoutExpired(argv, timeout, output=b"", stderr=b"")

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    result = acct.mysql_probe("db", 3306, "admin", "pw", database=None, sql="SELECT 1", timeout=10)

    assert result.timed_out is True
    assert result.returncode is None
    assert result.succeeded is False


def test_mysql_probe_propagates_missing_binary(monkeypatch):
    def fake_run(argv, timeout=None):
        raise FileNotFoundError("mysql")

    monkeypatch.setattr(acct.shell, "run_command", fake_run)

    with pytest.raises(OSError):
        acct.mysql_probe("db", 3306, "admin", "pw", database=None, sql="SELECT 1", timeout=10)


def test_mysql_probe_result_succeeded_property():
    assert acct.MysqlProbeResult(returncode=0, stdout="", stderr="", timed_out=False).succeeded is True
    assert acct.MysqlProbeResult(returncode=1, stdout="", stderr="", timed_out=False).succeeded is False
    assert acct.MysqlProbeResult(returncode=None, stdout="", stderr="", timed_out=True).succeeded is False


# --- config helper coverage via resolve_accounting_config -----------------------------


def test_resolve_config_reads_slurmdbd_port_from_scontrol(monkeypatch):
    # AccountingStoragePort comes from the effective (merged) config reported by scontrol.
    _stub_scontrol(monkeypatch, "AccountingStoragePort = 7777\n")
    context = _context_with_slurm_settings({"Database": {"Uri": "db:3306", "UserName": "admin"}})

    config = acct.resolve_accounting_config(context)

    assert config.slurmdbd_port == 7777


def test_resolve_config_defaults_slurmdbd_port_on_non_integer(monkeypatch):
    _stub_scontrol(monkeypatch, "AccountingStoragePort = not-a-port\n")
    context = _context_with_slurm_settings({"Database": {"Uri": "db:3306", "UserName": "admin"}})

    config = acct.resolve_accounting_config(context)

    assert config.slurmdbd_port == DEFAULT_SLURMDBD_PORT


def test_resolve_config_defaults_slurmdbd_port_when_scontrol_unavailable():
    # The autouse fixture makes scontrol absent; the local slurmdbd port falls back to the default.
    context = _context_with_slurm_settings({"Database": {"Uri": "db:3306", "UserName": "admin"}})

    assert acct.resolve_accounting_config(context).slurmdbd_port == DEFAULT_SLURMDBD_PORT


def test_resolve_config_region_prefers_dna_json():
    context = _context_with_slurm_settings({"Database": {"Uri": "db:3306"}})
    context.dna_json["cluster"]["region"] = "eu-west-1"

    assert acct.resolve_accounting_config(context).region == "eu-west-1"


def test_resolve_config_db_name_falls_back_to_stack_name():
    context = _context_with_slurm_settings({"Database": {"Uri": "db:3306"}})
    context.dna_json["cluster"]["stack_name"] = "stack-name"  # no cluster_name

    assert acct.resolve_accounting_config(context).db_name == "stack_name"


@pytest.mark.parametrize(
    "value, expected",
    [(None, ""), (b"bytes-output", "bytes-output"), ("str-output", "str-output")],
    ids=["none", "bytes", "str"],
)
def test_as_text_normalizes_output(value, expected):
    assert acct._as_text(value) == expected
