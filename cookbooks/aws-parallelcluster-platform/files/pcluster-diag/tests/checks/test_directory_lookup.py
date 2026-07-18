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

"""Unit tests for the directory-service checks: lookup latency, cluster-config management, resiliency."""

import pytest

from pcluster_diag.checks import directory_lookup
from pcluster_diag.checks.directory_lookup import (
    DirectoryBackendIsReachable,
    DirectoryBindCredentialsAreValid,
    DirectoryEndpointCertificateIsValid,
    DirectoryLookupLatency,
    DirectoryLookupResiliencySettings,
    DirectoryServiceManagedByClusterConfig,
    DirectoryUsersResolveUnderSearchBase,
)
from pcluster_diag.core.constants import (
    DIRECTORY_LOOKUP_FAIL_THRESHOLD_SECONDS,
    DIRECTORY_LOOKUP_WARN_THRESHOLD_SECONDS,
)
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.models.sssd_backend_status import SssdBackendStatus
from pcluster_diag.util.ldap import LDAP_INVALID_CREDENTIALS_CODE, ProbeResult
from pcluster_diag.util.shell import TimedCommand
from tests.sample_data import sample_context


@pytest.fixture(autouse=True)
def _isolate_sssd(monkeypatch, tmp_path):
    """Point SSSD_CONF_PATH at a path that does not exist unless a test writes it (never the real file)."""
    monkeypatch.setattr(directory_lookup, "SSSD_CONF_PATH", str(tmp_path / "sssd.conf"))


def _write_sssd(tmp_path, body):
    """Write ``body`` to the isolated sssd.conf path used by the tests."""
    (tmp_path / "sssd.conf").write_text(body, encoding="utf-8")


def _timed(returncode=0, stdout="entry", timed_out=False, elapsed=0.1):
    return TimedCommand(
        command=["lookup"],
        returncode=returncode,
        stdout=stdout,
        stderr="",
        elapsed_seconds=elapsed,
        timed_out=timed_out,
    )


def _context_with_directory_service(directory_service=None):
    context = sample_context(NodeType.HEAD)
    context.cluster_config["DirectoryService"] = directory_service or {"DomainName": "corp.example.com"}
    return context


def _use_targets(monkeypatch, groups, users):
    monkeypatch.setattr(DirectoryLookupLatency, "_derive_targets", lambda self, context: (groups, users))


# --- DirectoryLookupLatency: description / should_run ----------------------------------


def test_description():
    assert DirectoryLookupLatency().description == (
        "Measure directory service (NSS/SSSD/AD) lookup latency for cluster users and groups."
    )


def test_should_run_when_directory_service_in_cluster_config():
    assert DirectoryLookupLatency().should_run(_context_with_directory_service()) is True


def test_should_run_when_ad_configured_only_in_sssd(tmp_path):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    assert DirectoryLookupLatency().should_run(sample_context(NodeType.HEAD)) is True


def test_should_not_run_without_any_directory_integration():
    # No DirectoryService in cluster config and no (isolated) sssd.conf on disk.
    assert DirectoryLookupLatency().should_run(sample_context(NodeType.HEAD)) is False


# --- DirectoryLookupLatency: run -------------------------------------------------------


def test_run_not_applicable_when_no_targets_derivable(monkeypatch):
    _use_targets(monkeypatch, [], [])

    result = DirectoryLookupLatency().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryLookupLatency.NO_LOOKUP_TARGETS.code]


def test_run_passes_when_all_lookups_fast(monkeypatch):
    _use_targets(monkeypatch, ["hpc-users"], ["alice"])
    monkeypatch.setattr(directory_lookup, "time_command", lambda command, timeout: _timed(elapsed=0.2))

    result = DirectoryLookupLatency().run(_context_with_directory_service())

    assert result.status is Status.PASSED
    assert result.errors is None


def test_run_warns_when_latency_between_thresholds(monkeypatch):
    # Elevated-but-tolerable latency (between warn and fail thresholds) surfaces as a WARNING.
    _use_targets(monkeypatch, ["hpc-users"], [])
    elapsed = DIRECTORY_LOOKUP_WARN_THRESHOLD_SECONDS + 1
    monkeypatch.setattr(directory_lookup, "time_command", lambda command, timeout: _timed(elapsed=elapsed))

    result = DirectoryLookupLatency().run(_context_with_directory_service())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [DirectoryLookupLatency.ELEVATED_OR_UNRESOLVED_LOOKUPS.code]
    assert "elevated or unresolved" in result.warnings[0].message


def test_run_fails_when_latency_exceeds_fail_threshold(monkeypatch):
    _use_targets(monkeypatch, ["hpc-users"], [])
    elapsed = DIRECTORY_LOOKUP_FAIL_THRESHOLD_SECONDS + 1
    monkeypatch.setattr(directory_lookup, "time_command", lambda command, timeout: _timed(elapsed=elapsed))

    result = DirectoryLookupLatency().run(_context_with_directory_service())

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [DirectoryLookupLatency.SLOW_OR_FAILING_LOOKUPS.code]
    assert "slow or failing" in result.errors[0].message


def test_run_fails_when_lookup_times_out(monkeypatch):
    _use_targets(monkeypatch, [], ["alice"])
    monkeypatch.setattr(
        directory_lookup,
        "time_command",
        lambda command, timeout: _timed(returncode=None, timed_out=True, elapsed=30.0),
    )

    result = DirectoryLookupLatency().run(_context_with_directory_service())

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [DirectoryLookupLatency.SLOW_OR_FAILING_LOOKUPS.code]
    assert "timed out" in result.errors[0].message


def test_run_warns_when_name_not_resolvable(monkeypatch):
    _use_targets(monkeypatch, [], ["ghost"])
    # Fast but non-zero exit / empty output => name not resolvable, classified as warn => WARNING.
    monkeypatch.setattr(
        directory_lookup, "time_command", lambda command, timeout: _timed(returncode=2, stdout="", elapsed=0.05)
    )

    result = DirectoryLookupLatency().run(_context_with_directory_service())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [DirectoryLookupLatency.ELEVATED_OR_UNRESOLVED_LOOKUPS.code]
    assert "no entry resolved" in result.warnings[0].message


def test_run_issues_expected_lookup_commands(monkeypatch):
    _use_targets(monkeypatch, ["hpc-users"], ["alice"])
    commands = []

    def fake_time_command(command, timeout):
        commands.append(command)
        return _timed()

    monkeypatch.setattr(directory_lookup, "time_command", fake_time_command)

    DirectoryLookupLatency().run(_context_with_directory_service())

    assert commands == [
        ["getent", "group", "hpc-users"],
        ["getent", "passwd", "alice"],
        ["id", "alice"],
    ]


# --- DirectoryLookupLatency: target derivation and fallback ----------------------------


def test_derive_targets_reads_sssd_and_filters_local_accounts(tmp_path):
    _write_sssd(
        tmp_path,
        "[domain/default]\n"
        "simple_allow_groups = hpc-users, admins\n"
        "simple_allow_users = alice, root, nobody, bob\n",
    )

    groups, users = DirectoryLookupLatency()._derive_targets(sample_context(NodeType.HEAD))

    assert groups == ["hpc-users", "admins"]
    assert users == ["alice", "bob"]  # root and nobody filtered out


def test_derive_targets_falls_back_to_domain_read_only_user_from_cluster_config():
    # No simple_allow_* in sssd.conf; the cluster config manages the integration, so DomainReadOnlyUser
    # (a DN) is used, reduced to its CN component.
    context = _context_with_directory_service(
        {"DomainReadOnlyUser": "CN=ReadOnlyUser,OU=Users,DC=corp,DC=example,DC=com"}
    )

    groups, users = DirectoryLookupLatency()._derive_targets(context)

    assert groups == []
    assert users == ["ReadOnlyUser"]


def test_derive_targets_falls_back_to_bind_dn_when_not_managed_by_cluster_config(tmp_path):
    # No DirectoryService in cluster config and no simple_allow_*: fall back to sssd's ldap_default_bind_dn.
    _write_sssd(
        tmp_path,
        "[domain/default]\nid_provider = ldap\nldap_default_bind_dn = CN=svc-bind,OU=Svc,DC=corp,DC=com\n",
    )

    groups, users = DirectoryLookupLatency()._derive_targets(sample_context(NodeType.HEAD))

    assert groups == []
    assert users == ["svc-bind"]


def test_derive_targets_returns_empty_when_no_source_available():
    # No simple_allow_*, no DirectoryService, no sssd.conf on disk => nothing to probe.
    assert DirectoryLookupLatency()._derive_targets(sample_context(NodeType.HEAD)) == ([], [])


def test_run_uses_fallback_user_to_issue_probes(monkeypatch):
    context = _context_with_directory_service({"DomainReadOnlyUser": "svc-bind"})
    commands = []

    def fake_time_command(command, timeout):
        commands.append(command)
        return _timed()

    monkeypatch.setattr(directory_lookup, "time_command", fake_time_command)

    result = DirectoryLookupLatency().run(context)

    assert result.status is Status.PASSED
    assert commands == [["getent", "passwd", "svc-bind"], ["id", "svc-bind"]]


# --- DirectoryServiceManagedByClusterConfig -------------------------------------------


def test_managed_check_description():
    assert DirectoryServiceManagedByClusterConfig().description == (
        "Verify that an Active Directory integration is managed through the cluster configuration."
    )


def test_managed_check_should_run_matches_ad_presence(tmp_path):
    check = DirectoryServiceManagedByClusterConfig()
    # DirectoryService in cluster config.
    assert check.should_run(_context_with_directory_service()) is True
    # No integration at all.
    assert check.should_run(sample_context(NodeType.HEAD)) is False
    # AD only in sssd.conf.
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ad\n")
    assert check.should_run(sample_context(NodeType.HEAD)) is True


def test_managed_check_passes_when_declared_in_cluster_config():
    result = DirectoryServiceManagedByClusterConfig().run(_context_with_directory_service())

    assert result.status is Status.PASSED
    assert result.errors is None


def test_managed_check_warns_when_ad_not_in_cluster_config(tmp_path):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")

    result = DirectoryServiceManagedByClusterConfig().run(sample_context(NodeType.HEAD))

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [
        DirectoryServiceManagedByClusterConfig.AD_NOT_MANAGED_BY_CLUSTER_CONFIG.code
    ]
    assert "has no DirectoryService section" in result.warnings[0].message


# --- DirectoryLookupResiliencySettings ------------------------------------------------


def test_resiliency_check_description():
    assert DirectoryLookupResiliencySettings().description == (
        "Verify the settings that reduce directory-lookup load (Slurm NSS plugin, SSSD credential caching)."
    )


def test_resiliency_check_should_run_matches_ad_presence():
    check = DirectoryLookupResiliencySettings()
    assert check.should_run(_context_with_directory_service()) is True
    assert check.should_run(sample_context(NodeType.HEAD)) is False


def test_resiliency_check_passes_when_both_mitigations_enabled(monkeypatch):
    monkeypatch.setattr(directory_lookup, "_nss_slurm_enabled", lambda context: True)
    monkeypatch.setattr(directory_lookup, "_cache_credentials_enabled", lambda: True)

    result = DirectoryLookupResiliencySettings().run(_context_with_directory_service())

    assert result.status is Status.PASSED
    assert result.errors is None


def test_resiliency_check_warns_when_nss_slurm_disabled(monkeypatch):
    monkeypatch.setattr(directory_lookup, "_nss_slurm_enabled", lambda context: False)
    monkeypatch.setattr(directory_lookup, "_cache_credentials_enabled", lambda: True)

    result = DirectoryLookupResiliencySettings().run(_context_with_directory_service())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [
        DirectoryLookupResiliencySettings.NSS_SLURM_PLUGIN_DISABLED.code
    ]


def test_resiliency_check_warns_when_cache_credentials_disabled(monkeypatch):
    monkeypatch.setattr(directory_lookup, "_nss_slurm_enabled", lambda context: True)
    monkeypatch.setattr(directory_lookup, "_cache_credentials_enabled", lambda: False)

    result = DirectoryLookupResiliencySettings().run(_context_with_directory_service())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [
        DirectoryLookupResiliencySettings.SSSD_CACHE_CREDENTIALS_DISABLED.code
    ]


def test_resiliency_check_warns_with_both_advisories(monkeypatch):
    monkeypatch.setattr(directory_lookup, "_nss_slurm_enabled", lambda context: False)
    monkeypatch.setattr(directory_lookup, "_cache_credentials_enabled", lambda: False)

    result = DirectoryLookupResiliencySettings().run(_context_with_directory_service())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [
        DirectoryLookupResiliencySettings.NSS_SLURM_PLUGIN_DISABLED.code,
        DirectoryLookupResiliencySettings.SSSD_CACHE_CREDENTIALS_DISABLED.code,
    ]


def test_resiliency_check_no_nss_advisory_when_slurm_conf_unreadable(monkeypatch):
    # When slurm.conf cannot be read, nss_slurm state is unknown (None) and must not raise a false warning.
    monkeypatch.setattr(directory_lookup, "_nss_slurm_enabled", lambda context: None)
    monkeypatch.setattr(directory_lookup, "_cache_credentials_enabled", lambda: True)

    result = DirectoryLookupResiliencySettings().run(_context_with_directory_service())

    assert result.status is Status.PASSED


# --- module-level helpers -------------------------------------------------------------


@pytest.mark.parametrize(
    "value, expected",
    [
        ("CN=ReadOnlyUser,OU=Users,DC=corp,DC=com", "ReadOnlyUser"),
        ("cn=lower,DC=corp", "lower"),
        ("svc-bind", "svc-bind"),
        ("", None),
        (None, None),
    ],
    ids=["dn", "lowercase-cn", "bare-name", "empty", "none"],
)
def test_principal_from_dn(value, expected):
    assert directory_lookup._principal_from_dn(value) == expected


def test_nss_slurm_enabled_true_when_launch_parameter_present(tmp_path):
    slurm_etc = tmp_path / "etc"
    slurm_etc.mkdir()
    (slurm_etc / "slurm.conf").write_text("LaunchParameters=enable_nss_slurm,other\n", encoding="utf-8")
    context = sample_context(NodeType.HEAD)
    context.dna_json["cluster"]["slurm"] = {"install_dir": str(tmp_path)}

    assert directory_lookup._nss_slurm_enabled(context) is True


def test_nss_slurm_enabled_false_when_parameter_absent(tmp_path):
    slurm_etc = tmp_path / "etc"
    slurm_etc.mkdir()
    (slurm_etc / "slurm.conf").write_text("LaunchParameters=disable_send_gids\n", encoding="utf-8")
    context = sample_context(NodeType.HEAD)
    context.dna_json["cluster"]["slurm"] = {"install_dir": str(tmp_path)}

    assert directory_lookup._nss_slurm_enabled(context) is False


def test_nss_slurm_enabled_none_when_slurm_conf_missing(tmp_path):
    context = sample_context(NodeType.HEAD)
    context.dna_json["cluster"]["slurm"] = {"install_dir": str(tmp_path / "missing")}

    assert directory_lookup._nss_slurm_enabled(context) is None


@pytest.mark.parametrize(
    "body, expected",
    [
        ("[domain/default]\ncache_credentials = True\n", True),
        ("[domain/default]\ncache_credentials = False\n", False),
        ("[domain/default]\nid_provider = ldap\n", False),  # absent => disabled (SSSD default)
    ],
    ids=["true", "false", "absent"],
)
def test_cache_credentials_enabled(tmp_path, body, expected):
    _write_sssd(tmp_path, body)
    assert directory_lookup._cache_credentials_enabled() is expected


def test_read_sssd_value_returns_none_for_absent_key(tmp_path):
    _write_sssd(tmp_path, "[sssd]\nservices = nss, pam\n")

    assert directory_lookup._read_sssd_value("simple_allow_groups") is None


@pytest.mark.parametrize(
    "output, expected",
    [
        ("Online status: Online", True),
        ("Online status: Offline", False),
        ("Name: default\nOnline status: Offline\nActive server: x", False),  # skips leading non-match lines
        ("Online status: degraded\nActive server: x", None),  # 'Online status' present but unrecognized value
        ("Active server: x\nno status here", None),  # no 'Online status' line
        ("", None),
    ],
    ids=["online", "offline", "offline-after-other-lines", "unrecognized-status", "no-status-line", "empty"],
)
def test_parse_online_status(output, expected):
    assert directory_lookup._parse_online_status(output) is expected


# --- DirectoryBackendIsReachable ------------------------------------------------------


def _backend(summary, online):
    """Build an SssdBackendStatus stub for monkeypatching _sssd_backend_status."""
    return SssdBackendStatus(summary=summary, online=online)


def test_backend_check_description():
    assert DirectoryBackendIsReachable().description == (
        "Verify that SSSD reports the directory backend (AD/LDAP) online."
    )


def test_backend_check_should_run_matches_ad_presence(tmp_path):
    check = DirectoryBackendIsReachable()
    assert check.should_run(_context_with_directory_service()) is True
    assert check.should_run(sample_context(NodeType.HEAD)) is False
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    assert check.should_run(sample_context(NodeType.HEAD)) is True


def test_backend_check_failures_when_backend_offline(monkeypatch):
    monkeypatch.setattr(
        directory_lookup, "_sssd_backend_status", lambda: _backend("default: Online status: Offline", False)
    )

    result = DirectoryBackendIsReachable().run(_context_with_directory_service())

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [DirectoryBackendIsReachable.BACKEND_OFFLINE.code]
    assert "offline" in result.errors[0].message


def test_backend_check_passes_when_backend_online(monkeypatch):
    monkeypatch.setattr(
        directory_lookup, "_sssd_backend_status", lambda: _backend("default: Online status: Online", True)
    )

    result = DirectoryBackendIsReachable().run(_context_with_directory_service())

    assert result.status is Status.PASSED
    assert result.errors is None


def test_backend_check_passes_when_status_unknown(monkeypatch):
    # online=None (sssctl responded but reported no parseable status) must not warn.
    monkeypatch.setattr(directory_lookup, "_sssd_backend_status", lambda: _backend("default: some status", None))

    result = DirectoryBackendIsReachable().run(_context_with_directory_service())

    assert result.status is Status.PASSED


def test_backend_check_skipped_when_status_undeterminable(monkeypatch):
    # sssctl unavailable / errored / no AD domain -> _sssd_backend_status returns None -> cannot assess.
    monkeypatch.setattr(directory_lookup, "_sssd_backend_status", lambda: None)

    result = DirectoryBackendIsReachable().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryBackendIsReachable.STATUS_UNAVAILABLE.code]


# --- sssctl backend-status helpers ----------------------------------------------------


def _sssctl_output(stdout, returncode=0, timed_out=False):
    """Build a TimedCommand as if returned by an sssctl domain-status invocation."""
    return TimedCommand(
        command=["sssctl", "domain-status", "default"],
        returncode=returncode,
        stdout=stdout,
        stderr="",
        elapsed_seconds=0.1,
        timed_out=timed_out,
    )


def test_ad_domain_names_returns_only_ldap_ad_domains(tmp_path):
    _write_sssd(
        tmp_path,
        "[sssd]\ndomains = default, local\n"
        "[domain/default]\nid_provider = ad\n"
        "[domain/local]\nid_provider = files\n",
    )

    assert directory_lookup._ad_domain_names() == ["default"]


def test_ad_domain_names_empty_when_sssd_missing():
    # The autouse fixture points SSSD_CONF_PATH at a file that does not exist.
    assert directory_lookup._ad_domain_names() == []


def test_sssd_backend_status_summarizes_domain_status(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    commands = []

    def fake_time_command(command, timeout):
        commands.append(command)
        return _sssctl_output("Online status: Online\nActive server: ad.example.com\n")

    monkeypatch.setattr(directory_lookup, "time_command", fake_time_command)

    status = directory_lookup._sssd_backend_status()
    assert status.summary == "default: Online status: Online; Active server: ad.example.com"
    assert status.online is True
    assert commands == [["sssctl", "domain-status", "default"]]


def test_sssd_backend_status_reports_offline(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ad\n")
    monkeypatch.setattr(
        directory_lookup, "time_command", lambda command, timeout: _sssctl_output("Online status: Offline\n")
    )

    status = directory_lookup._sssd_backend_status()
    assert status.online is False
    assert "Offline" in status.summary


def test_sssd_backend_status_online_unknown_when_not_reported(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    monkeypatch.setattr(
        directory_lookup, "time_command", lambda command, timeout: _sssctl_output("Active server: ad.example.com\n")
    )

    status = directory_lookup._sssd_backend_status()
    assert status.online is None


def test_sssd_backend_status_none_when_no_ad_domain(tmp_path):
    _write_sssd(tmp_path, "[domain/local]\nid_provider = files\n")

    assert directory_lookup._sssd_backend_status() is None


def test_sssd_backend_status_none_when_sssctl_missing(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ad\n")

    def raise_not_found(command, timeout):
        raise FileNotFoundError("sssctl")

    monkeypatch.setattr(directory_lookup, "time_command", raise_not_found)

    assert directory_lookup._sssd_backend_status() is None


def test_sssd_backend_status_skips_nonzero_or_timed_out(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    monkeypatch.setattr(directory_lookup, "time_command", lambda command, timeout: _sssctl_output("boom", returncode=1))
    assert directory_lookup._sssd_backend_status() is None

    monkeypatch.setattr(directory_lookup, "time_command", lambda command, timeout: _sssctl_output("", timed_out=True))
    assert directory_lookup._sssd_backend_status() is None


def test_sssd_backend_status_none_when_output_blank(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    monkeypatch.setattr(directory_lookup, "time_command", lambda command, timeout: _sssctl_output("  \n  \n"))

    assert directory_lookup._sssd_backend_status() is None


# --- DirectoryEndpointCertificateIsValid ----------------------------------------------


def _probe(returncode=0, stdout="", stderr="", timed_out=False):
    """Build a util.ldap.ProbeResult stub."""
    return ProbeResult(returncode=returncode, stdout=stdout, stderr=stderr, timed_out=timed_out)


def test_cert_check_should_run_only_with_ldaps_endpoint(tmp_path):
    check = DirectoryEndpointCertificateIsValid()
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\n")
    assert check.should_run(sample_context(NodeType.HEAD)) is True
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldap://ad.example.com\n")
    assert check.should_run(sample_context(NodeType.HEAD)) is False


# A real Amazon Linux 2023 (OpenSSL 3.x) failure: the trailing "Verify return code" line is a
# misleading 0, the true failure is only in the "verify error" / "Verification error" lines.
_AL2023_BAD_CERT_OUTPUT = (
    "CONNECTED(00000003)\n"
    "depth=0 CN=microsoftad.example.pcluster\n"
    "verify error:num=18:self-signed certificate\n"
    "Verification error: self-signed certificate\n"
    "---\n"
    "SSL handshake has read 964 bytes and written 362 bytes\n"
    "Verify return code: 0 (ok)\n"
)


def test_cert_check_passes_when_certificate_validates(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\n")
    monkeypatch.setattr(
        directory_lookup.ldap,
        "verify_tls_certificate",
        lambda *a, **k: _probe(0, "depth=0 CN=ad\nverify return:1\nVerify return code: 0 (ok)"),
    )

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.errors is None


def test_cert_check_fails_on_al2023_bad_cert_despite_verify_return_code_zero(tmp_path, monkeypatch):
    # reqcert unset defaults to hard => an invalid cert is fatal. The AL2023 output ends with
    # "Verify return code: 0 (ok)" but is a genuine failure: the check must not be fooled.
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\n")
    monkeypatch.setattr(
        directory_lookup.ldap, "verify_tls_certificate", lambda *a, **k: _probe(1, _AL2023_BAD_CERT_OUTPUT)
    )

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [DirectoryEndpointCertificateIsValid.INVALID_CERTIFICATE.code]
    assert "self-signed certificate" in result.errors[0].message


def test_cert_check_passes_when_invalid_but_reqcert_relaxed(tmp_path, monkeypatch):
    # With a relaxed ldap_tls_reqcert (allow/never/try) SSSD proceeds despite the invalid certificate,
    # so the check passes rather than flagging it.
    _write_sssd(
        tmp_path,
        "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\nldap_tls_reqcert = allow\n",
    )
    monkeypatch.setattr(
        directory_lookup.ldap, "verify_tls_certificate", lambda *a, **k: _probe(1, _AL2023_BAD_CERT_OUTPUT)
    )

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.PASSED
    assert result.warnings is None


def test_cert_check_skipped_when_openssl_missing(tmp_path, monkeypatch):
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\n")

    def raise_not_found(*a, **k):
        raise FileNotFoundError("openssl")

    monkeypatch.setattr(directory_lookup.ldap, "verify_tls_certificate", raise_not_found)

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryEndpointCertificateIsValid.OPENSSL_UNAVAILABLE.code]


def test_cert_check_skipped_when_no_handshake(tmp_path, monkeypatch):
    # A timeout means the endpoint was unreachable: not this check's concern.
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\n")
    monkeypatch.setattr(directory_lookup.ldap, "verify_tls_certificate", lambda *a, **k: _probe(None, timed_out=True))

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryEndpointCertificateIsValid.NOT_VALIDATED.code]


def test_cert_check_skipped_when_connection_refused(tmp_path, monkeypatch):
    # No TLS handshake evidence (connection refused) => reachability, not a certificate answer.
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldaps://ad.example.com\n")
    monkeypatch.setattr(
        directory_lookup.ldap, "verify_tls_certificate", lambda *a, **k: _probe(1, stderr="connect:errno=111")
    )

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryEndpointCertificateIsValid.NOT_VALIDATED.code]


# --- DirectoryBindCredentialsAreValid -------------------------------------------------

_BIND_SSSD = (
    "[domain/default]\n"
    "id_provider = ldap\n"
    "ldap_uri = ldaps://ad.example.com\n"
    "ldap_default_bind_dn = CN=svc,DC=corp,DC=com\n"
    "ldap_default_authtok = s3cret\n"
)


def test_bind_check_passes_when_bind_succeeds(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _BIND_SSSD)
    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", lambda *a, **k: _probe(0, "dn: DC=corp,DC=com"))

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.PASSED


def test_bind_check_fails_on_invalid_credentials(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _BIND_SSSD)
    monkeypatch.setattr(
        directory_lookup.ldap,
        "ldap_bind_search",
        lambda *a, **k: _probe(LDAP_INVALID_CREDENTIALS_CODE, stderr="bind failed"),
    )

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [DirectoryBindCredentialsAreValid.INVALID_CREDENTIALS.code]


def test_bind_check_fails_on_other_bind_error(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _BIND_SSSD)
    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", lambda *a, **k: _probe(None, timed_out=True))

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.FAILURE
    assert [error.code for error in result.errors] == [DirectoryBindCredentialsAreValid.BIND_ERROR.code]
    assert "timed out" in result.errors[0].message


def test_bind_check_tries_next_endpoint_when_first_unreachable(tmp_path, monkeypatch):
    # Two endpoints: the first is unreachable (times out); the bind must still pass on the second.
    _write_sssd(
        tmp_path,
        _BIND_SSSD.replace(
            "ldap_uri = ldaps://ad.example.com", "ldap_uri = ldaps://a.example.com ldaps://b.example.com"
        ),
    )
    seen = []

    def fake_search(uri, *a, **k):
        seen.append(uri)
        return _probe(None, timed_out=True) if uri == "ldaps://a.example.com" else _probe(0, "dn: DC=corp,DC=com")

    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", fake_search)

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.PASSED
    assert seen == ["ldaps://a.example.com", "ldaps://b.example.com"]


def test_bind_check_skipped_when_authtok_obfuscated(tmp_path):
    _write_sssd(tmp_path, _BIND_SSSD + "ldap_default_authtok_type = obfuscated_password\n")

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryBindCredentialsAreValid.CANNOT_VERIFY.code]


def test_bind_check_skipped_when_ldapsearch_missing(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _BIND_SSSD)

    def raise_not_found(*a, **k):
        raise FileNotFoundError("ldapsearch")

    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", raise_not_found)

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE


def test_bind_check_skipped_when_no_endpoint(tmp_path):
    # Credentials present but no ldap_uri => cannot bind.
    _write_sssd(
        tmp_path,
        "[domain/default]\nid_provider = ldap\nldap_default_bind_dn = CN=svc,DC=corp\nldap_default_authtok = s3cret\n",
    )

    result = DirectoryBindCredentialsAreValid().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE


# --- DirectoryUsersResolveUnderSearchBase ---------------------------------------------

_MEMBERSHIP_SSSD = _BIND_SSSD + "ldap_search_base = DC=corp,DC=com\nsimple_allow_users = alice, bob\n"


def test_membership_check_passes_when_all_users_found(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _MEMBERSHIP_SSSD)
    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", lambda *a, **k: _probe(0, "dn: CN=x,DC=corp,DC=com"))

    result = DirectoryUsersResolveUnderSearchBase().run(_context_with_directory_service())

    assert result.status is Status.PASSED


def test_membership_check_warns_when_user_missing(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _MEMBERSHIP_SSSD)
    # alice resolves (dn present); bob returns an empty (but successful) search => not under base.
    calls = {"n": 0}

    def fake_search(*a, **k):
        calls["n"] += 1
        return _probe(0, "dn: CN=alice,DC=corp,DC=com") if calls["n"] == 1 else _probe(0, "")

    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", fake_search)

    result = DirectoryUsersResolveUnderSearchBase().run(_context_with_directory_service())

    assert result.status is Status.WARNING
    assert [warning.code for warning in result.warnings] == [
        DirectoryUsersResolveUnderSearchBase.USER_NOT_UNDER_BASE.code
    ]
    assert "bob" in result.warnings[0].message and "alice" not in result.warnings[0].message


def test_membership_check_skipped_when_search_errors(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _MEMBERSHIP_SSSD)
    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", lambda *a, **k: _probe(1, stderr="server down"))

    result = DirectoryUsersResolveUnderSearchBase().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE
    assert [info.code for info in result.infos] == [DirectoryUsersResolveUnderSearchBase.SEARCH_INCOMPLETE.code]


def test_membership_check_tries_next_endpoint_when_first_search_errors(tmp_path, monkeypatch):
    # Two endpoints: the first cannot complete a search; the second resolves every user => PASSED.
    _write_sssd(
        tmp_path,
        _MEMBERSHIP_SSSD.replace(
            "ldap_uri = ldaps://ad.example.com", "ldap_uri = ldaps://a.example.com ldaps://b.example.com"
        ),
    )
    seen = []

    def fake_search(uri, *a, **k):
        seen.append(uri)
        return _probe(1, stderr="server down") if uri == "ldaps://a.example.com" else _probe(0, "dn: CN=x,DC=corp")

    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", fake_search)

    result = DirectoryUsersResolveUnderSearchBase().run(_context_with_directory_service())

    assert result.status is Status.PASSED
    # First endpoint aborts after one failed search; the second resolves both users.
    assert seen == ["ldaps://a.example.com", "ldaps://b.example.com", "ldaps://b.example.com"]


def test_membership_check_skipped_when_no_base_or_users(tmp_path):
    # Credentials + endpoint but no search base and no allow-listed users.
    _write_sssd(tmp_path, _BIND_SSSD)

    result = DirectoryUsersResolveUnderSearchBase().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE


# --- LDAP helper functions ------------------------------------------------------------


def test_ldap_endpoints_parses_scheme_host_port(tmp_path):
    # A malformed token (no hostname) is skipped; valid ldaps/ldap tokens are parsed with default ports.
    _write_sssd(tmp_path, "[domain/default]\nldap_uri = ldaps://a.example.com garbage ldap://b.example.com:1389\n")

    assert directory_lookup._ldap_endpoints() == [
        ("ldaps://a.example.com", "a.example.com", 636, "ldaps"),
        ("ldap://b.example.com:1389", "b.example.com", 1389, "ldap"),
    ]


@pytest.mark.parametrize(
    "check_cls",
    [DirectoryBindCredentialsAreValid, DirectoryUsersResolveUnderSearchBase],
)
def test_ldap_checks_should_run_matches_ad_presence(check_cls, tmp_path):
    assert check_cls().should_run(_context_with_directory_service()) is True
    assert check_cls().should_run(sample_context(NodeType.HEAD)) is False
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\n")
    assert check_cls().should_run(sample_context(NodeType.HEAD)) is True


def test_cert_check_skipped_when_no_ldaps_endpoint(tmp_path):
    # run() called directly with only a non-TLS endpoint -> nothing to validate.
    _write_sssd(tmp_path, "[domain/default]\nid_provider = ldap\nldap_uri = ldap://ad.example.com\n")

    result = DirectoryEndpointCertificateIsValid().run(sample_context(NodeType.HEAD))

    assert result.status is Status.SKIPPED_NOT_APPLICABLE


def test_membership_check_skipped_when_ldapsearch_missing(tmp_path, monkeypatch):
    _write_sssd(tmp_path, _MEMBERSHIP_SSSD)

    def raise_not_found(*a, **k):
        raise FileNotFoundError("ldapsearch")

    monkeypatch.setattr(directory_lookup.ldap, "ldap_bind_search", raise_not_found)

    result = DirectoryUsersResolveUnderSearchBase().run(_context_with_directory_service())

    assert result.status is Status.SKIPPED_NOT_APPLICABLE


def test_ldap_bind_credentials_none_when_obfuscated(tmp_path):
    _write_sssd(
        tmp_path,
        "[domain/default]\nldap_default_bind_dn = CN=svc\nldap_default_authtok = x\n"
        "ldap_default_authtok_type = obfuscated_password\n",
    )
    assert directory_lookup._ldap_bind_credentials() is None


def test_ldap_bind_credentials_returns_plaintext(tmp_path):
    _write_sssd(tmp_path, "[domain/default]\nldap_default_bind_dn = CN=svc\nldap_default_authtok = pw\n")
    assert directory_lookup._ldap_bind_credentials() == ("CN=svc", "pw")


def test_ldap_search_base_prefers_user_search_base(tmp_path):
    _write_sssd(tmp_path, "[domain/default]\nldap_search_base = DC=corp\nldap_user_search_base = OU=Users,DC=corp\n")
    assert directory_lookup._ldap_search_base() == "OU=Users,DC=corp"


@pytest.mark.parametrize(
    "value, expected",
    [("alice", "alice"), ("a*b", "a\\2ab"), ("a(b)", "a\\28b\\29"), ("a\\b", "a\\5cb")],
    ids=["plain", "star", "parens", "backslash"],
)
def test_ldap_escape(value, expected):
    assert directory_lookup._ldap_escape(value) == expected
