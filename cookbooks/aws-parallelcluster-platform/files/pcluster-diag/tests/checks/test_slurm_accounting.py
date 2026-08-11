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

"""Unit tests for the SlurmAccounting check: aggregate Result plus per-probe behavior."""

import subprocess

import pytest

from pcluster_diag.checks import slurm_accounting
from pcluster_diag.checks.slurm_accounting import SlurmAccounting
from pcluster_diag.core.constants import (
    ACCOUNTING_QUERY_LATENCY_FAIL_THRESHOLD_SECONDS,
    ACCOUNTING_QUERY_LATENCY_WARN_THRESHOLD_SECONDS,
)
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Status
from pcluster_diag.util.network import DnsResult, TcpResult
from pcluster_diag.util.path_permissions import PathStat
from pcluster_diag.util.shell import TimedCommand
from pcluster_diag.util.slurm_accounting import (
    AccountingConfig,
    MysqlProbeResult,
    SecretAccessDenied,
    SecretNotFound,
)
from tests.sample_data import sample_context

# --- config builders ------------------------------------------------------------------


def _local_config(**overrides):
    base = dict(
        is_external=False,
        slurmdbd_host="localhost",
        slurmdbd_port=6819,
        db_host="db.example.com",
        db_port=3306,
        db_user="admin",
        db_name="acct_db",
        password_secret_arn="arn:aws:secretsmanager:us-east-1:1:secret:pw",
        region="us-east-1",
    )
    base.update(overrides)
    return AccountingConfig(**base)


def _external_config(**overrides):
    base = dict(
        is_external=True,
        slurmdbd_host="ext.example.com",
        slurmdbd_port=6819,
        db_host=None,
        db_port=None,
        db_user=None,
        db_name=None,
        password_secret_arn=None,
        region="us-east-1",
    )
    base.update(overrides)
    return AccountingConfig(**base)


def _mysql(returncode=0, stdout="", stderr="", timed_out=False):
    return MysqlProbeResult(returncode=returncode, stdout=stdout, stderr=stderr, timed_out=timed_out)


def _timed(returncode=0, stdout="", stderr="", elapsed=0.1, timed_out=False):
    return TimedCommand(
        command=["sacctmgr"],
        returncode=returncode,
        stdout=stdout,
        stderr=stderr,
        elapsed_seconds=elapsed,
        timed_out=timed_out,
    )


def _codes(findings):
    return [finding.code for finding in findings]


# --- description / should_run ---------------------------------------------------------


def test_description_mentions_the_capability():
    assert "accounting" in SlurmAccounting().description.lower()


def test_should_not_run_on_compute_node():
    assert SlurmAccounting().should_run(sample_context(NodeType.COMPUTE)) is False


def test_should_run_on_head_when_declared_in_config(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: True)
    monkeypatch.setattr(slurm_accounting, "accounting_present_on_node", lambda: False)
    assert SlurmAccounting().should_run(sample_context(NodeType.HEAD)) is True


def test_should_run_on_head_when_present_on_node_only(monkeypatch):
    # Accounting set up out-of-band (present on the node but not declared in the cluster config).
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: False)
    monkeypatch.setattr(slurm_accounting, "accounting_present_on_node", lambda: True)
    assert SlurmAccounting().should_run(sample_context(NodeType.HEAD)) is True


def test_should_not_run_on_head_when_no_accounting_anywhere(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: False)
    monkeypatch.setattr(slurm_accounting, "accounting_present_on_node", lambda: False)
    assert SlurmAccounting().should_run(sample_context(NodeType.HEAD)) is False


# --- run(): aggregation, password-resolved-once, isolation ----------------------------


def _silence_all(monkeypatch):
    """Make every probe contribute nothing (clean cluster)."""
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: True)
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=True, error=None))
    monkeypatch.setattr(slurm_accounting, "resolve_host", lambda *a, **k: DnsResult(resolved=True, error=None))
    monkeypatch.setattr(slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=0, stdout="GRANT ALL"))
    monkeypatch.setattr(slurm_accounting, "parse_keyvalue_conf", lambda path: {})
    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", lambda path: PathStat("slurm", "slurm", "0600"))
    monkeypatch.setattr(slurm_accounting, "_is_readable", lambda path: True)
    monkeypatch.setattr(slurm_accounting.shell, "time_command", lambda command, timeout: _timed(elapsed=0.1))
    monkeypatch.setattr(slurm_accounting, "_read_logs", lambda *paths: "")


def test_run_passes_when_capability_clean(monkeypatch):
    _silence_all(monkeypatch)
    monkeypatch.setattr(slurm_accounting, "resolve_accounting_config", lambda context: _external_config())

    result = SlurmAccounting().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.errors is None
    assert result.warnings is None


def test_run_resolves_password_exactly_once(monkeypatch):
    _silence_all(monkeypatch)
    monkeypatch.setattr(slurm_accounting, "resolve_accounting_config", lambda context: _local_config())
    calls = {"n": 0}

    def counting_resolve(config):
        calls["n"] += 1
        return "s3cret"

    monkeypatch.setattr(slurm_accounting, "_resolve_password", counting_resolve)
    monkeypatch.setattr(slurm_accounting, "get_secret_string", lambda arn, region: "s3cret")

    SlurmAccounting().run(sample_context(NodeType.HEAD))

    # The password is resolved once in run() and threaded through the probes, not re-fetched per probe.
    assert calls["n"] == 1


def test_run_fails_when_a_probe_reports_an_error(monkeypatch):
    _silence_all(monkeypatch)
    monkeypatch.setattr(slurm_accounting, "resolve_accounting_config", lambda context: _external_config())
    # slurmdbd endpoint unreachable => an expected error dominates the aggregate.
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=False, error="refused"))

    result = SlurmAccounting().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert SlurmAccounting.SLURMDBD_UNREACHABLE.code in _codes(result.errors)


def test_run_isolates_an_unexpected_probe_crash(monkeypatch):
    _silence_all(monkeypatch)
    monkeypatch.setattr(slurm_accounting, "resolve_accounting_config", lambda context: _external_config())

    def boom(*a, **k):
        raise RuntimeError("boom")

    monkeypatch.setattr(slurm_accounting, "tcp_connect", boom)

    result = SlurmAccounting().run(sample_context(NodeType.HEAD))

    assert result.status is Status.CHECK_ERROR
    assert "E{}".format(INTERNAL_ERROR_CODE) in _codes(result.errors)


def test_run_password_resolution_failure_does_not_sink_the_check(monkeypatch):
    _silence_all(monkeypatch)
    monkeypatch.setattr(
        slurm_accounting, "resolve_accounting_config", lambda context: _local_config(password_secret_arn=None)
    )

    def boom():
        raise RuntimeError("cannot read slurmdbd conf")

    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", boom)

    result = SlurmAccounting().run(sample_context(NodeType.HEAD))

    # A resolution failure degrades to a coverage gap, not a CHECK_ERROR/FAILURE.
    assert result.status is Status.PASSED


# --- management probe -----------------------------------------------------------------


def test_management_probe_silent_when_declared_in_config(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: True)
    warnings = []

    SlurmAccounting()._probe_managed_by_cluster_config(sample_context(NodeType.HEAD), warnings)

    assert warnings == []


def test_management_probe_warns_when_present_on_node_but_not_declared(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: False)
    warnings = []

    SlurmAccounting()._probe_managed_by_cluster_config(sample_context(NodeType.HEAD), warnings)

    assert _codes(warnings) == [SlurmAccounting.ACCOUNTING_NOT_MANAGED_BY_CLUSTER_CONFIG.code]


def test_run_warns_when_accounting_not_managed_by_cluster_config(monkeypatch):
    # Present on the node but absent from the cluster config: the run surfaces the management warning.
    _silence_all(monkeypatch)
    monkeypatch.setattr(slurm_accounting, "resolve_accounting_config", lambda context: _external_config())
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: False)

    result = SlurmAccounting().run(sample_context(NodeType.HEAD))

    assert result.status is Status.WARNING
    assert SlurmAccounting.ACCOUNTING_NOT_MANAGED_BY_CLUSTER_CONFIG.code in _codes(result.warnings)


def test_run_out_of_band_local_still_runs_database_probes(monkeypatch):
    # Accounting present on the node but not declared in the cluster config: the config resolves the
    # database fields from Slurm's own state, so the database-facing probes run instead of no-op'ing.
    # A rejected-credentials verdict here proves the credential probe actually executed.
    _silence_all(monkeypatch)
    monkeypatch.setattr(slurm_accounting, "accounting_declared_in_config", lambda context: False)
    monkeypatch.setattr(
        slurm_accounting, "resolve_accounting_config", lambda context: _local_config(password_secret_arn=None)
    )
    monkeypatch.setattr(slurm_accounting, "_resolve_password", lambda config: "from-storage-pass")
    monkeypatch.setattr(slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=1, stderr="Access denied"))

    result = SlurmAccounting().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert SlurmAccounting.CREDENTIALS_INVALID.code in _codes(result.errors)
    # The management warning still fires alongside the now-active database probe.
    assert SlurmAccounting.ACCOUNTING_NOT_MANAGED_BY_CLUSTER_CONFIG.code in _codes(result.warnings or [])


# --- slurmdbd endpoint probe (merged reachability + accepting) ------------------------


def test_endpoint_probe_silent_when_connected(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=True, error=None))
    errors = []

    SlurmAccounting()._probe_slurmdbd_endpoint(_local_config(), errors)

    assert errors == []


def test_endpoint_probe_reports_unreachable_when_not_active(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=False, error="refused"))
    monkeypatch.setattr(slurm_accounting, "_slurmdbd_reports_active", lambda: False)
    errors = []

    SlurmAccounting()._probe_slurmdbd_endpoint(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.SLURMDBD_UNREACHABLE.code]


def test_endpoint_probe_reports_up_but_not_accepting_when_active(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=False, error="refused"))
    monkeypatch.setattr(slurm_accounting, "_slurmdbd_reports_active", lambda: True)
    errors = []

    SlurmAccounting()._probe_slurmdbd_endpoint(_local_config(), errors)

    # Exactly one finding: the "active but not accepting" case does not double-report unreachable.
    assert _codes(errors) == [SlurmAccounting.SLURMDBD_UP_BUT_NOT_ACCEPTING.code]


def test_endpoint_probe_external_mode_never_consults_systemd(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=False, error="refused"))

    def fail_if_called():
        raise AssertionError("systemctl must not be consulted in ExternalSlurmdbd mode")

    monkeypatch.setattr(slurm_accounting, "_slurmdbd_reports_active", fail_if_called)
    errors = []

    SlurmAccounting()._probe_slurmdbd_endpoint(_external_config(), errors)

    assert _codes(errors) == [SlurmAccounting.SLURMDBD_UNREACHABLE.code]


def test_endpoint_probe_silent_when_endpoint_unknown():
    errors = []
    SlurmAccounting()._probe_slurmdbd_endpoint(_external_config(slurmdbd_host=None, slurmdbd_port=None), errors)
    assert errors == []


# --- database reachability probe ------------------------------------------------------


def test_database_probe_silent_in_external_mode():
    errors = []
    SlurmAccounting()._probe_database_reachable(_external_config(), errors)
    assert errors == []


def test_database_probe_fails_on_dns_failure(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "resolve_host", lambda *a, **k: DnsResult(resolved=False, error="nxdomain"))
    errors = []

    SlurmAccounting()._probe_database_reachable(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.DB_DNS_RESOLUTION_FAILED.code]


def test_database_probe_fails_on_port_unreachable(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "resolve_host", lambda *a, **k: DnsResult(resolved=True, error=None))
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=False, error="refused"))
    errors = []

    SlurmAccounting()._probe_database_reachable(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.DB_PORT_UNREACHABLE.code]


def test_database_probe_silent_when_reachable(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "resolve_host", lambda *a, **k: DnsResult(resolved=True, error=None))
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=True, error=None))
    errors = []

    SlurmAccounting()._probe_database_reachable(_local_config(), errors)

    assert errors == []


# --- password reserved-character probe ------------------------------------------------


def test_reserved_char_probe_silent_in_external_mode():
    errors = []
    SlurmAccounting()._probe_password_reserved_char(_external_config(), "has#hash", errors)
    assert errors == []


def test_reserved_char_probe_silent_when_password_unresolved():
    errors = []
    SlurmAccounting()._probe_password_reserved_char(_local_config(), None, errors)
    assert errors == []


def test_reserved_char_probe_fails_on_hash():
    errors = []
    SlurmAccounting()._probe_password_reserved_char(_local_config(), "bad#pass", errors)
    assert _codes(errors) == [SlurmAccounting.PASSWORD_HAS_RESERVED_CHAR.code]


def test_reserved_char_probe_silent_on_clean_password():
    errors = []
    SlurmAccounting()._probe_password_reserved_char(_local_config(), "cleanpass", errors)
    assert errors == []


# --- secret well-formed probe ---------------------------------------------------------


def test_secret_probe_silent_in_external_mode():
    errors = []
    SlurmAccounting()._probe_secret_well_formed(_external_config(), errors)
    assert errors == []


def test_secret_probe_silent_without_arn():
    errors = []
    SlurmAccounting()._probe_secret_well_formed(_local_config(password_secret_arn=None), errors)
    assert errors == []


def test_secret_probe_fails_on_access_denied(monkeypatch):
    def deny(arn, region):
        raise SecretAccessDenied(arn)

    monkeypatch.setattr(slurm_accounting, "get_secret_string", deny)
    errors = []

    SlurmAccounting()._probe_secret_well_formed(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.SECRET_MISSING_IAM_PERMISSION.code]


def test_secret_probe_silent_when_secret_not_found(monkeypatch):
    def missing(arn, region):
        raise SecretNotFound(arn)

    monkeypatch.setattr(slurm_accounting, "get_secret_string", missing)
    errors = []

    SlurmAccounting()._probe_secret_well_formed(_local_config(), errors)

    assert errors == []


def test_secret_probe_fails_on_json_object(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "get_secret_string", lambda arn, region: '{"password": "p"}')
    errors = []

    SlurmAccounting()._probe_secret_well_formed(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.SECRET_IS_JSON_OBJECT.code]


def test_secret_probe_silent_on_plaintext(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "get_secret_string", lambda arn, region: "plaintext")
    errors = []

    SlurmAccounting()._probe_secret_well_formed(_local_config(), errors)

    assert errors == []


# --- credentials probe ----------------------------------------------------------------


def test_credentials_probe_silent_in_external_mode():
    errors, warnings = [], []
    SlurmAccounting()._probe_credentials_valid(_external_config(), "pw", errors, warnings)
    assert errors == [] and warnings == []


def test_credentials_probe_silent_when_inputs_missing():
    errors, warnings = [], []
    SlurmAccounting()._probe_credentials_valid(_local_config(), None, errors, warnings)
    assert errors == [] and warnings == []


def test_credentials_probe_warns_when_mysql_unavailable(monkeypatch):
    def missing(*a, **k):
        raise FileNotFoundError("mysql")

    monkeypatch.setattr(slurm_accounting, "mysql_probe", missing)
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert errors == []
    assert _codes(warnings) == [SlurmAccounting.MYSQL_UNAVAILABLE.code]


def test_credentials_probe_fails_on_timeout(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=None, timed_out=True))
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert _codes(errors) == [SlurmAccounting.AUTH_TIMED_OUT.code]


def test_credentials_probe_fails_on_rejected_credentials(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=1, stderr="Access denied"))
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert _codes(errors) == [SlurmAccounting.CREDENTIALS_INVALID.code]


def test_credentials_probe_fails_on_database_access_denied(monkeypatch):
    # First probe (auth, database=None) succeeds; second probe (against db_name) is denied.
    def probe(host, port, user, password, database, sql, timeout, secret_for_redaction=None):
        if database is None:
            return _mysql(returncode=0)
        return _mysql(returncode=1, stderr="access denied to db")

    monkeypatch.setattr(slurm_accounting, "mysql_probe", probe)
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert _codes(errors) == [SlurmAccounting.DATABASE_ACCESS_DENIED.code]


def test_credentials_probe_silent_when_valid(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=0))
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert errors == [] and warnings == []


# --- configuration-files probe --------------------------------------------------------


def test_config_files_probe_silent_in_external_mode():
    errors = []
    SlurmAccounting()._probe_config_files(_external_config(), errors)
    assert errors == []


def test_config_files_probe_fails_when_missing(monkeypatch):
    def missing(path):
        raise FileNotFoundError(path)

    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", missing)
    errors = []

    SlurmAccounting()._probe_config_files(_local_config(), errors)

    # Both accounting conf files are reported missing.
    assert _codes(errors) == [SlurmAccounting.CONF_FILE_MISSING.code, SlurmAccounting.CONF_FILE_MISSING.code]


def test_config_files_probe_flags_wrong_ownership_and_mode(monkeypatch):
    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", lambda path: PathStat("root", "root", "0644"))
    monkeypatch.setattr(slurm_accounting, "_is_readable", lambda path: True)
    errors = []

    SlurmAccounting()._probe_config_files(_local_config(), errors)

    codes = _codes(errors)
    assert SlurmAccounting.CONF_WRONG_OWNERSHIP.code in codes
    assert SlurmAccounting.CONF_WRONG_MODE.code in codes


def test_config_files_probe_flags_unreadable(monkeypatch):
    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", lambda path: PathStat("slurm", "slurm", "0600"))
    monkeypatch.setattr(slurm_accounting, "_is_readable", lambda path: False)
    errors = []

    SlurmAccounting()._probe_config_files(_local_config(), errors)

    assert SlurmAccounting.CONF_FILE_UNREADABLE.code in _codes(errors)


def test_config_files_probe_silent_when_correct(monkeypatch):
    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", lambda path: PathStat("slurm", "slurm", "0600"))
    monkeypatch.setattr(slurm_accounting, "_is_readable", lambda path: True)
    errors = []

    SlurmAccounting()._probe_config_files(_local_config(), errors)

    assert errors == []


def test_accounting_conf_files_declare_their_expectation_as_allowed_modes():
    # This probe only evaluates allowed_modes, so a required/forbidden-bits entry would go uninspected.
    for expected in slurm_accounting._ACCOUNTING_CONF_FILES:
        assert expected.allowed_modes, expected.path


@pytest.mark.parametrize("mode", ["0600", "0640"])
def test_config_files_probe_accepts_every_mode_slurmdbd_allows(monkeypatch, mode):
    # slurmdbd accepts 600 or 640 and exits fatal on anything else, so 0640 must not be reported.
    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", lambda path: PathStat("slurm", "slurm", mode))
    monkeypatch.setattr(slurm_accounting, "_is_readable", lambda path: True)
    errors = []

    SlurmAccounting()._probe_config_files(_local_config(), errors)

    assert errors == []


@pytest.mark.parametrize("mode", ["0400", "0644", "0660"])
def test_config_files_probe_flags_modes_slurmdbd_rejects(monkeypatch, mode):
    # Anything outside {600, 640} makes slurmdbd exit fatal, including stricter modes such as 0400.
    monkeypatch.setattr(slurm_accounting.path_permissions, "stat_path", lambda path: PathStat("slurm", "slurm", mode))
    monkeypatch.setattr(slurm_accounting, "_is_readable", lambda path: True)
    errors = []

    SlurmAccounting()._probe_config_files(_local_config(), errors)

    assert SlurmAccounting.CONF_WRONG_MODE.code in _codes(errors)
    assert "should be 0600 or 0640" in " | ".join(error.message for error in errors)


# --- configuration-consistency probe --------------------------------------------------


def test_config_consistency_probe_silent_in_external_mode():
    errors = []
    SlurmAccounting()._probe_config_consistent(_external_config(), errors)
    assert errors == []


def test_config_consistency_probe_silent_when_conf_unreadable(monkeypatch):
    def unreadable(path):
        raise OSError("cannot read")

    monkeypatch.setattr(slurm_accounting, "parse_keyvalue_conf", unreadable)
    errors = []

    SlurmAccounting()._probe_config_consistent(_local_config(), errors)

    assert errors == []


def test_config_consistency_probe_fails_on_host_mismatch(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting,
        "parse_keyvalue_conf",
        lambda path: {"StorageHost": "other.example.com", "StoragePort": "3306"},
    )
    errors = []

    SlurmAccounting()._probe_config_consistent(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.CONFIG_ENDPOINT_INCONSISTENT.code]
    assert "StorageHost" in errors[0].message


def test_config_consistency_probe_fails_on_port_mismatch(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting,
        "parse_keyvalue_conf",
        lambda path: {"StorageHost": "db.example.com", "StoragePort": "9999"},
    )
    errors = []

    SlurmAccounting()._probe_config_consistent(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.CONFIG_ENDPOINT_INCONSISTENT.code]
    assert "StoragePort" in errors[0].message


def test_config_consistency_probe_silent_when_consistent(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting,
        "parse_keyvalue_conf",
        lambda path: {"StorageHost": "db.example.com", "StoragePort": "3306"},
    )
    errors = []

    SlurmAccounting()._probe_config_consistent(_local_config(), errors)

    assert errors == []


# --- database-privileges probe --------------------------------------------------------


def test_privileges_probe_silent_in_external_mode():
    errors, warnings = [], []
    SlurmAccounting()._probe_db_privileges(_external_config(), "pw", errors, warnings)
    assert errors == [] and warnings == []


def test_privileges_probe_warns_when_mysql_unavailable(monkeypatch):
    def missing(*a, **k):
        raise FileNotFoundError("mysql")

    monkeypatch.setattr(slurm_accounting, "mysql_probe", missing)
    errors, warnings = [], []

    SlurmAccounting()._probe_db_privileges(_local_config(), "pw", errors, warnings)

    assert _codes(warnings) == [SlurmAccounting.MYSQL_UNAVAILABLE.code]


def test_privileges_probe_fails_when_privileges_missing(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=0, stdout="GRANT SELECT ON db.* TO admin")
    )
    errors, warnings = [], []

    SlurmAccounting()._probe_db_privileges(_local_config(), "pw", errors, warnings)

    assert _codes(errors) == [SlurmAccounting.DB_MISSING_PRIVILEGES.code]
    assert "CREATE" in errors[0].message


def test_privileges_probe_silent_when_all_privileges_present(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=0, stdout="GRANT ALL PRIVILEGES ON *.*")
    )
    errors, warnings = [], []

    SlurmAccounting()._probe_db_privileges(_local_config(), "pw", errors, warnings)

    assert errors == [] and warnings == []


def test_privileges_probe_silent_when_grants_query_fails(monkeypatch):
    # A failed/empty grants query is reported by the credentials probe, not here.
    monkeypatch.setattr(slurm_accounting, "mysql_probe", lambda *a, **k: _mysql(returncode=1, stderr="denied"))
    errors, warnings = [], []

    SlurmAccounting()._probe_db_privileges(_local_config(), "pw", errors, warnings)

    assert errors == [] and warnings == []


# --- end-to-end query probe -----------------------------------------------------------


def test_query_probe_warns_when_sacctmgr_unavailable(monkeypatch):
    def missing(command, timeout):
        raise FileNotFoundError("sacctmgr")

    monkeypatch.setattr(slurm_accounting.shell, "time_command", missing)
    errors, warnings = [], []

    SlurmAccounting()._probe_queries_healthy(errors, warnings)

    assert _codes(warnings) == [SlurmAccounting.SACCTMGR_UNAVAILABLE.code]


def test_query_probe_fails_on_timeout(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting.shell,
        "time_command",
        lambda command, timeout: _timed(returncode=None, timed_out=True, elapsed=30.0),
    )
    errors, warnings = [], []

    SlurmAccounting()._probe_queries_healthy(errors, warnings)

    assert _codes(errors) == [SlurmAccounting.QUERY_FAILED.code]
    assert "timed out" in errors[0].message


def test_query_probe_fails_on_nonzero_exit(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting.shell, "time_command", lambda command, timeout: _timed(returncode=1, stderr="boom")
    )
    errors, warnings = [], []

    SlurmAccounting()._probe_queries_healthy(errors, warnings)

    assert _codes(errors) == [SlurmAccounting.QUERY_FAILED.code]


def test_query_probe_fails_on_excessive_latency(monkeypatch):
    elapsed = ACCOUNTING_QUERY_LATENCY_FAIL_THRESHOLD_SECONDS + 1
    monkeypatch.setattr(slurm_accounting.shell, "time_command", lambda command, timeout: _timed(elapsed=elapsed))
    errors, warnings = [], []

    SlurmAccounting()._probe_queries_healthy(errors, warnings)

    assert _codes(errors) == [SlurmAccounting.QUERY_EXCESSIVE_LATENCY.code]


def test_query_probe_warns_on_elevated_latency(monkeypatch):
    elapsed = ACCOUNTING_QUERY_LATENCY_WARN_THRESHOLD_SECONDS + 0.5
    monkeypatch.setattr(slurm_accounting.shell, "time_command", lambda command, timeout: _timed(elapsed=elapsed))
    errors, warnings = [], []

    SlurmAccounting()._probe_queries_healthy(errors, warnings)

    assert errors == []
    assert _codes(warnings) == [SlurmAccounting.QUERY_ELEVATED_LATENCY.code]


def test_query_probe_silent_when_fast(monkeypatch):
    monkeypatch.setattr(slurm_accounting.shell, "time_command", lambda command, timeout: _timed(elapsed=0.05))
    errors, warnings = [], []

    SlurmAccounting()._probe_queries_healthy(errors, warnings)

    assert errors == [] and warnings == []


# --- logs probe -----------------------------------------------------------------------


def test_logs_probe_fails_on_version_incompatibility(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting, "_read_logs", lambda *paths: "error: Failed to unpack SLURM_PERSIST_INIT message"
    )
    errors = []

    SlurmAccounting()._probe_logs(errors)

    assert _codes(errors) == [SlurmAccounting.LOG_VERSION_INCOMPATIBILITY.code]


def test_logs_probe_fails_on_cluster_id_mismatch(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "_read_logs", lambda *paths: "fatal: CLUSTER ID MISMATCH detected")
    monkeypatch.setattr(slurm_accounting, "_read_state_cluster_name", lambda: "my-cluster")
    errors = []

    SlurmAccounting()._probe_logs(errors)

    assert _codes(errors) == [SlurmAccounting.LOG_CLUSTER_ID_MISMATCH.code]
    assert "my-cluster" in errors[0].message


def test_logs_probe_silent_when_clean(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "_read_logs", lambda *paths: "everything is fine")
    errors = []

    SlurmAccounting()._probe_logs(errors)

    assert errors == []


# --- module-level helpers -------------------------------------------------------------


@pytest.mark.parametrize(
    "grants, expected_missing",
    [
        ("GRANT ALL PRIVILEGES ON *.* TO admin", []),
        ("GRANT CREATE, SELECT, INSERT ON db.* TO admin", []),
        ("GRANT SELECT ON db.* TO admin", ["CREATE", "INSERT/UPDATE (write)"]),
        ("GRANT USAGE ON *.* TO admin", ["CREATE", "SELECT (read)", "INSERT/UPDATE (write)"]),
    ],
    ids=["all", "explicit-crud", "read-only", "usage-only"],
)
def test_missing_privileges(grants, expected_missing):
    assert slurm_accounting._missing_privileges(grants) == expected_missing


def test_first_missing_input_reports_first_absent_input():
    assert slurm_accounting._first_missing_input(_local_config(db_host=None), "pw") is not None
    assert slurm_accounting._first_missing_input(_local_config(), "pw") is None
    assert slurm_accounting._first_missing_input(_local_config(), None) is not None


def test_resolve_password_none_in_external_mode(monkeypatch):
    # External mode: the credential lives on the external instance, so no source is even consulted.
    def fail_if_called(*a, **k):
        raise AssertionError("no password source must be consulted in ExternalSlurmdbd mode")

    monkeypatch.setattr(slurm_accounting, "get_secret_string", fail_if_called)
    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", fail_if_called)

    assert slurm_accounting._resolve_password(_external_config()) is None


def test_resolve_password_swallows_unexpected_error(monkeypatch):
    def boom(arn, region):
        raise RuntimeError("secrets manager unreachable")

    monkeypatch.setattr(slurm_accounting, "get_secret_string", boom)

    # An unexpected failure degrades to None rather than propagating into run().
    assert slurm_accounting._resolve_password(_local_config()) is None


def test_resolve_password_prefers_secret(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "get_secret_string", lambda arn, region: "from-secret")
    assert slurm_accounting._resolve_password(_local_config()) == "from-secret"


def test_resolve_password_falls_back_to_conf_when_secret_errors(monkeypatch):
    # A Secret* error is swallowed here (the secret probe reports it) and StoragePass is used instead.
    def missing(arn, region):
        raise SecretNotFound(arn)

    monkeypatch.setattr(slurm_accounting, "get_secret_string", missing)
    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", lambda: {"StoragePass": "from-conf"})

    assert slurm_accounting._resolve_password(_local_config()) == "from-conf"


def test_resolve_password_falls_back_to_storage_pass(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", lambda: {"StoragePass": "from-conf"})

    password = slurm_accounting._resolve_password(_local_config(password_secret_arn=None))

    assert password == "from-conf"


def test_resolve_password_ignores_template_default(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", lambda: {"StoragePass": "dummy"})

    assert slurm_accounting._resolve_password(_local_config(password_secret_arn=None)) is None


# --- additional edge branches ---------------------------------------------------------


def test_database_probe_silent_when_endpoint_unknown():
    errors = []
    SlurmAccounting()._probe_database_reachable(_local_config(db_host=None, db_port=None), errors)
    assert errors == []


def test_credentials_probe_warns_when_mysql_unavailable_during_db_access(monkeypatch):
    # Auth (database=None) succeeds, but the mysql client disappears before the db-access probe.
    def probe(host, port, user, password, database, sql, timeout, secret_for_redaction=None):
        if database is None:
            return _mysql(returncode=0)
        raise FileNotFoundError("mysql")

    monkeypatch.setattr(slurm_accounting, "mysql_probe", probe)
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert errors == []
    assert _codes(warnings) == [SlurmAccounting.MYSQL_UNAVAILABLE.code]


def test_credentials_probe_fails_when_db_access_times_out(monkeypatch):
    def probe(host, port, user, password, database, sql, timeout, secret_for_redaction=None):
        if database is None:
            return _mysql(returncode=0)
        return _mysql(returncode=None, timed_out=True)

    monkeypatch.setattr(slurm_accounting, "mysql_probe", probe)
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(), "pw", errors, warnings)

    assert _codes(errors) == [SlurmAccounting.AUTH_TIMED_OUT.code]


def test_credentials_probe_skips_db_access_when_no_db_name(monkeypatch):
    seen = []

    def probe(host, port, user, password, database, sql, timeout, secret_for_redaction=None):
        seen.append(database)
        return _mysql(returncode=0)

    monkeypatch.setattr(slurm_accounting, "mysql_probe", probe)
    errors, warnings = [], []

    SlurmAccounting()._probe_credentials_valid(_local_config(db_name=None), "pw", errors, warnings)

    assert errors == [] and warnings == []
    assert seen == [None]  # only the auth probe ran, never a per-database probe


def test_config_consistency_probe_fails_on_non_integer_port(monkeypatch):
    monkeypatch.setattr(
        slurm_accounting,
        "parse_keyvalue_conf",
        lambda path: {"StorageHost": "db.example.com", "StoragePort": "not-a-port"},
    )
    errors = []

    SlurmAccounting()._probe_config_consistent(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.CONFIG_ENDPOINT_INCONSISTENT.code]
    assert "not a valid port" in errors[0].message


@pytest.mark.parametrize(
    "config",
    [_local_config(db_port=None), _local_config(db_user=None)],
    ids=["no-port", "no-user"],
)
def test_first_missing_input_flags_absent_port_and_user(config):
    assert slurm_accounting._first_missing_input(config, "pw") is not None


def test_resolve_password_returns_none_when_conf_unavailable(monkeypatch):
    # read_slurmdbd_conf swallows unreadable/absent files and yields an empty map -> no StoragePass.
    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", lambda: {})

    assert slurm_accounting._resolve_password(_local_config(password_secret_arn=None)) is None


def test_resolve_password_returns_none_when_storage_pass_absent(monkeypatch):
    monkeypatch.setattr(slurm_accounting, "read_slurmdbd_conf", lambda: {"StorageHost": "db"})

    assert slurm_accounting._resolve_password(_local_config(password_secret_arn=None)) is None


# --- filesystem/log helpers -----------------------------------------------------------


def test_is_readable_true_for_readable_file(tmp_path):
    path = tmp_path / "readable"
    path.write_text("data", encoding="utf-8")
    assert slurm_accounting._is_readable(str(path)) is True


def test_is_readable_false_on_permission_error(monkeypatch):
    def deny(*a, **k):
        raise PermissionError("nope")

    monkeypatch.setattr("builtins.open", deny)
    assert slurm_accounting._is_readable("/some/path") is False


def test_is_readable_true_on_non_permission_oserror(monkeypatch):
    # A non-permission error (e.g. a race that removed the file) is not a readability finding.
    def raise_oserror(*a, **k):
        raise FileNotFoundError("gone")

    monkeypatch.setattr("builtins.open", raise_oserror)
    assert slurm_accounting._is_readable("/some/path") is True


def test_read_logs_concatenates_readable_and_skips_missing(tmp_path):
    present = tmp_path / "slurmctld.log"
    present.write_text("controller line", encoding="utf-8")
    missing = tmp_path / "slurmdbd.log"  # never created

    logs = slurm_accounting._read_logs(str(present), str(missing))

    assert "controller line" in logs


def test_read_logs_reads_only_the_tail(tmp_path, monkeypatch):
    # A stale signature outside the tail window must not be seen; the recent slice must be.
    log = tmp_path / "slurmctld.log"
    log.write_text("STALE_SIGNATURE\n" + ("filler line\n" * 500) + "RECENT_SIGNATURE\n", encoding="utf-8")
    monkeypatch.setattr(slurm_accounting, "LOG_SCAN_TAIL_BYTES", 200)

    logs = slurm_accounting._read_logs(str(log))

    assert "RECENT_SIGNATURE" in logs
    assert "STALE_SIGNATURE" not in logs


def test_logs_probe_ignores_remediated_signature_outside_tail(tmp_path, monkeypatch):
    # An already-fixed version incompatibility scrolled out of the tail window no longer fails.
    log = tmp_path / "slurmctld.log"
    log.write_text(
        "Incompatible versions of client and server code\n" + ("routine line\n" * 500),
        encoding="utf-8",
    )
    monkeypatch.setattr(slurm_accounting, "SLURMCTLD_LOG_PATH", str(log))
    monkeypatch.setattr(slurm_accounting, "SLURMDBD_LOG_PATH", str(tmp_path / "absent.log"))
    monkeypatch.setattr(slurm_accounting, "LOG_SCAN_TAIL_BYTES", 200)
    errors = []

    SlurmAccounting()._probe_logs(errors)

    assert errors == []


def test_logs_probe_still_fails_on_recent_signature(tmp_path, monkeypatch):
    log = tmp_path / "slurmctld.log"
    log.write_text(
        ("routine line\n" * 500) + "Incompatible versions of client and server code\n",
        encoding="utf-8",
    )
    monkeypatch.setattr(slurm_accounting, "SLURMCTLD_LOG_PATH", str(log))
    monkeypatch.setattr(slurm_accounting, "SLURMDBD_LOG_PATH", str(tmp_path / "absent.log"))
    monkeypatch.setattr(slurm_accounting, "LOG_SCAN_TAIL_BYTES", 200)
    errors = []

    SlurmAccounting()._probe_logs(errors)

    assert _codes(errors) == [SlurmAccounting.LOG_VERSION_INCOMPATIBILITY.code]


def test_read_tail_returns_whole_small_file(tmp_path):
    log = tmp_path / "small.log"
    log.write_text("line one\nline two\n", encoding="utf-8")

    # The file is smaller than the window, so nothing is dropped.
    assert slurm_accounting._read_tail(str(log), 4096) == "line one\nline two\n"


def test_read_tail_drops_partial_first_line(tmp_path):
    log = tmp_path / "big.log"
    log.write_text("aaaaaaaaaa\nbbbbbbbbbb\ncccccccccc\n", encoding="utf-8")

    # A window starting mid-line drops that fragment so a signature never matches a partial line.
    tail = slurm_accounting._read_tail(str(log), 16)

    assert tail == "cccccccccc\n"
    assert not tail.startswith("b")


def test_read_tail_replaces_split_multibyte_character(tmp_path):
    log = tmp_path / "utf8.log"
    # A multi-byte character straddling the truncation point must not raise.
    log.write_bytes(("x" * 10 + "\n" + "\u00e9" * 10 + "\n").encode("utf-8"))

    tail = slurm_accounting._read_tail(str(log), 9)

    assert isinstance(tail, str)


def test_read_tail_keeps_window_when_it_contains_no_newline(tmp_path):
    log = tmp_path / "oneline.log"
    log.write_text("x" * 100, encoding="utf-8")  # a single line longer than the window

    # No newline to split on, so the window is returned as-is rather than discarded.
    assert slurm_accounting._read_tail(str(log), 10) == "x" * 10


def test_read_tail_raises_oserror_for_missing_file(tmp_path):
    with pytest.raises(OSError):
        slurm_accounting._read_tail(str(tmp_path / "nope.log"), 4096)


def test_read_state_cluster_name_reads_and_strips(tmp_path, monkeypatch):
    clustername = tmp_path / "clustername"
    clustername.write_text("my-cluster\n", encoding="utf-8")
    monkeypatch.setattr(slurm_accounting, "SLURM_STATE_CLUSTERNAME_PATH", str(clustername))

    assert slurm_accounting._read_state_cluster_name() == "my-cluster"


def test_read_state_cluster_name_none_when_absent(tmp_path, monkeypatch):
    monkeypatch.setattr(slurm_accounting, "SLURM_STATE_CLUSTERNAME_PATH", str(tmp_path / "missing"))
    assert slurm_accounting._read_state_cluster_name() is None


def test_slurmdbd_reports_active_reflects_systemctl(monkeypatch):
    monkeypatch.setattr(slurm_accounting.shell, "run_command", lambda command, timeout: _FakeActive("active"))
    assert slurm_accounting._slurmdbd_reports_active() is True
    monkeypatch.setattr(slurm_accounting.shell, "run_command", lambda command, timeout: _FakeActive("inactive"))
    assert slurm_accounting._slurmdbd_reports_active() is False


@pytest.mark.parametrize(
    "error",
    [FileNotFoundError("systemctl"), subprocess.TimeoutExpired(["systemctl"], 10)],
    ids=["systemctl-missing", "systemctl-timeout"],
)
def test_slurmdbd_reports_active_false_when_systemd_unqueryable(monkeypatch, error):
    def raise_error(command, timeout):
        raise error

    monkeypatch.setattr(slurm_accounting.shell, "run_command", raise_error)

    assert slurm_accounting._slurmdbd_reports_active() is False


@pytest.mark.parametrize(
    "error",
    [FileNotFoundError("systemctl"), subprocess.TimeoutExpired(["systemctl"], 10)],
    ids=["systemctl-missing", "systemctl-timeout"],
)
def test_endpoint_probe_still_reports_unreachable_when_systemd_unqueryable(monkeypatch, error):
    # An unanswerable systemd query must not cost the probe its finding (it would become an E0
    # CHECK_ERROR and the actionable unreachable finding would be lost).
    monkeypatch.setattr(slurm_accounting, "tcp_connect", lambda *a, **k: TcpResult(connected=False, error="refused"))

    def raise_error(command, timeout):
        raise error

    monkeypatch.setattr(slurm_accounting.shell, "run_command", raise_error)
    errors = []

    SlurmAccounting()._probe_slurmdbd_endpoint(_local_config(), errors)

    assert _codes(errors) == [SlurmAccounting.SLURMDBD_UNREACHABLE.code]


class _FakeActive:
    def __init__(self, stdout):
        self.stdout = stdout
        self.stderr = ""
        self.returncode = 0
