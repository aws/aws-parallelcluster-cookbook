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

"""Checks about the directory service (NSS -> SSSD -> LDAP/AD) integration.

slurmctld resolves users and groups through NSS on its main control thread (e.g. AllowGroups refresh,
job credential creation). When those lookups are slow, the controller's periodic loop is delayed, node
pings are missed, and healthy compute nodes can be marked DOWN/NOT_RESPONDING and recycled. This module
provides:

- ``DirectoryLookupLatency``: times the exact NSS calls slurmctld depends on (``getent group``,
  ``getent passwd``, ``id``) and flags lookups slow enough to put the controller at risk.
- ``DirectoryBackendIsReachable``: consults a read-only ``sssctl domain-status`` and fails when SSSD
  reports the directory backend offline.
- ``DirectoryServiceManagedByClusterConfig``: warns when an AD/LDAP integration exists on the node but
  is not declared in the cluster configuration (so ParallelCluster cannot manage or validate it).
- ``DirectoryLookupResiliencySettings``: warns when the settings that reduce directory-lookup load
  (the Slurm NSS plugin and SSSD credential caching) are not enabled.
- ``DirectoryEndpointCertificateIsValid``: runs a read-only openssl TLS handshake and reports when the
  directory endpoint's certificate does not validate against the configured CA.
- ``DirectoryBindCredentialsAreValid``: reproduces SSSD's bind with a read-only ``ldapsearch`` to verify
  the configured bind DN and password.
- ``DirectoryUsersResolveUnderSearchBase``: searches the configured LDAP base (read-only ``ldapsearch``)
  to confirm the allow-listed users actually resolve under it.

All checks are read-only and safe to run on a production node. The ldapsearch/openssl-based checks are
best-effort: they record SKIPPED_NOT_APPLICABLE when the tool or the required input is unavailable.
"""

import configparser
import logging
import re
import urllib.parse
from pathlib import Path
from typing import List, Optional, Tuple

from pcluster_diag.core.constants import (
    DEFAULT_SLURM_INSTALL_DIR,
    DIRECTORY_LOOKUP_COMMAND_TIMEOUT_SECONDS,
    DIRECTORY_LOOKUP_FAIL_THRESHOLD_SECONDS,
    DIRECTORY_LOOKUP_WARN_THRESHOLD_SECONDS,
    NSS_SLURM_LAUNCH_PARAMETER,
    SLURM_CONF_RELATIVE_PATH,
    SSSD_CONF_PATH,
)
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckInfo, CheckWarning
from pcluster_diag.models.result import Result
from pcluster_diag.models.sssd_backend_status import SssdBackendStatus
from pcluster_diag.util import ldap
from pcluster_diag.util.shell import time_command

logger = logging.getLogger(__name__)

_STATUS_OK = "ok"
_STATUS_WARN = "warn"
_STATUS_FAIL = "fail"


class DirectoryLookupLatency(Check):
    """Measure NSS/SSSD/AD lookup latency for the users and groups Slurm resolves."""

    SLOW_OR_FAILING_LOOKUPS = CheckError(
        1,
        "Directory lookups are slow or failing: {}. They are expected to resolve quickly and reliably.",
    )
    ELEVATED_OR_UNRESOLVED_LOOKUPS = CheckWarning(
        1,
        "Directory lookups are elevated or unresolved: {}. They are expected to resolve quickly and reliably.",
    )
    NO_LOOKUP_TARGETS = CheckInfo(
        1,
        "No lookup users/groups could be derived: sssd.conf has no simple_allow_groups/simple_allow_users "
        "and no DomainReadOnlyUser (cluster config) or ldap_default_bind_dn (sssd.conf) fallback.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Measure directory service (NSS/SSSD/AD) lookup latency for cluster users and groups."

    def should_run(self, context: Context) -> bool:
        """Run only when the node integrates a directory service (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Time getent/id lookups and fail when any exceeds the fail threshold or times out.

        When no lookup targets can be derived, the check does not apply, so it is recorded as
        SKIPPED_NOT_APPLICABLE. Lookups over the fail threshold (or that time out) produce a FAILURE.
        Elevated-but-tolerable latency, or a name that does not resolve, produces a WARNING.
        """
        groups, users = self._derive_targets(context)
        if not groups and not users:
            return Result.skipped_not_applicable(self, infos=[self.NO_LOOKUP_TARGETS])

        probes = []
        for group in groups:
            probes.append(self._probe(["getent", "group", group], "getent group {}".format(group)))
        for user in users:
            probes.append(self._probe(["getent", "passwd", user], "getent passwd {}".format(user)))
            probes.append(self._probe(["id", user], "id {}".format(user)))

        failures = [text for status, text in probes if status == _STATUS_FAIL]
        if failures:
            return Result.failure(self, errors=[self.SLOW_OR_FAILING_LOOKUPS.format("; ".join(failures))])

        warnings = [text for status, text in probes if status == _STATUS_WARN]
        if warnings:
            return Result.warning(self, warnings=[self.ELEVATED_OR_UNRESOLVED_LOOKUPS.format("; ".join(warnings))])
        return Result.passed(self)

    def _probe(self, command: List[str], label: str) -> Tuple[str, str]:
        """Run one timed lookup and return ``(status, text)`` classified against the latency thresholds.

        ``status`` is one of the ``_STATUS_*`` tokens; ``text`` is a human-readable "``label (detail)``"
        summary used verbatim in the Result message.
        """
        timed = time_command(command, timeout=DIRECTORY_LOOKUP_COMMAND_TIMEOUT_SECONDS)
        if timed.timed_out:
            status, detail = _STATUS_FAIL, "timed out after {:.0f}s".format(timed.elapsed_seconds)
        elif timed.returncode != 0 or not timed.stdout.strip():
            # Name not resolvable is a correctness signal, not latency; report it as a warning.
            status, detail = _STATUS_WARN, "no entry resolved in {:.3f}s".format(timed.elapsed_seconds)
        elif timed.elapsed_seconds > DIRECTORY_LOOKUP_FAIL_THRESHOLD_SECONDS:
            status, detail = _STATUS_FAIL, "took {:.3f}s (> {:.0f}s fail threshold)".format(
                timed.elapsed_seconds, DIRECTORY_LOOKUP_FAIL_THRESHOLD_SECONDS
            )
        elif timed.elapsed_seconds > DIRECTORY_LOOKUP_WARN_THRESHOLD_SECONDS:
            status, detail = _STATUS_WARN, "took {:.3f}s (> {:.0f}s warn threshold)".format(
                timed.elapsed_seconds, DIRECTORY_LOOKUP_WARN_THRESHOLD_SECONDS
            )
        else:
            status, detail = _STATUS_OK, "took {:.3f}s".format(timed.elapsed_seconds)
        return status, "{} ({})".format(label, detail)

    def _derive_targets(self, context: Context) -> Tuple[List[str], List[str]]:
        """Derive lookup targets, preferring sssd.conf's simple_allow_groups / simple_allow_users.

        Returns a ``(groups, users)`` tuple. ``root`` and ``nobody`` are filtered out as local accounts.
        When neither simple_allow_* list yields a target (e.g. the cluster uses an LDAP access filter
        instead of the simple access provider), fall back to a single known directory account so the
        latency probe can still run. Missing/unparseable sources yield empty lists (the Check then
        reports SKIPPED_NOT_APPLICABLE).
        """
        groups = _split_csv(_read_sssd_value("simple_allow_groups"))
        users = [user for user in _split_csv(_read_sssd_value("simple_allow_users")) if user not in ("root", "nobody")]
        if not groups and not users:
            fallback = self._fallback_user(context)
            if fallback:
                users = [fallback]
        return groups, users

    @staticmethod
    def _fallback_user(context: Context) -> Optional[str]:
        """Return a single directory account to probe when no simple_allow_* target is available.

        When the integration is managed by the cluster configuration, use its ``DomainReadOnlyUser``
        (the read-only bind account, always resolvable through the directory). Otherwise the integration
        was set up outside the cluster configuration, so fall back to sssd.conf's ``ldap_default_bind_dn``.
        Either value may be a full DN, in which case the CN component is used as the lookup name.
        """
        directory_service = _directory_service_config(context)
        if directory_service:
            raw = directory_service.get("DomainReadOnlyUser")
        else:
            raw = _read_sssd_value("ldap_default_bind_dn")
        return _principal_from_dn(raw)


class DirectoryServiceManagedByClusterConfig(Check):
    """Warn when an AD/LDAP integration exists on the node but is not declared in the cluster config."""

    AD_NOT_MANAGED_BY_CLUSTER_CONFIG = CheckWarning(
        1,
        "An Active Directory integration is configured in {} but the cluster configuration has no "
        "DirectoryService section. The integration was set up outside ParallelCluster, so ParallelCluster cannot manage"
        " or validate it and the configuration may be "
        "lost on a cluster update. Move the integration into the cluster configuration's DirectoryService section.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that an Active Directory integration is managed through the cluster configuration."

    def should_run(self, context: Context) -> bool:
        """Run only when the node has an AD/LDAP integration (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Pass when the integration is declared in the cluster config; warn otherwise."""
        if _directory_service_config(context):
            return Result.passed(self)
        return Result.warning(self, warnings=[self.AD_NOT_MANAGED_BY_CLUSTER_CONFIG.format(SSSD_CONF_PATH)])


class DirectoryLookupResiliencySettings(Check):
    """Warn when the settings that reduce directory-lookup load are not enabled."""

    NSS_SLURM_PLUGIN_DISABLED = CheckWarning(
        1,
        "The Slurm NSS plugin is not enabled ({} is absent from LaunchParameters in slurm.conf); it is "
        "expected to be enabled to reduce directory-lookup load on compute nodes.",
    )
    SSSD_CACHE_CREDENTIALS_DISABLED = CheckWarning(
        2,
        "SSSD credential caching is not enabled (cache_credentials is not set to True in {}); it is "
        "expected to be enabled so SSSD can serve cached identities when the backend is slow or briefly "
        "unavailable.",
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify the settings that reduce directory-lookup load (Slurm NSS plugin, SSSD credential caching)."

    def should_run(self, context: Context) -> bool:
        """Run only when the node has an AD/LDAP integration (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Warn when the Slurm NSS plugin or SSSD credential caching is not enabled; pass otherwise."""
        advisories = []
        if _nss_slurm_enabled(context) is False:
            advisories.append(self.NSS_SLURM_PLUGIN_DISABLED.format(NSS_SLURM_LAUNCH_PARAMETER))
        if not _cache_credentials_enabled():
            advisories.append(self.SSSD_CACHE_CREDENTIALS_DISABLED.format(SSSD_CONF_PATH))
        if advisories:
            return Result.warning(self, warnings=advisories)
        return Result.passed(self)


class DirectoryBackendIsReachable(Check):
    """Fail when SSSD reports the directory backend offline.

    A ``getent``/``id`` lookup can be served from the SSSD cache, so DirectoryLookupLatency passing does
    not prove the backend is reachable. This check consults SSSD directly (``sssctl domain-status``): an
    offline backend means identities are being served from cache and will start failing once it expires,
    which can stall slurmctld and block logins.
    """

    BACKEND_OFFLINE = CheckError(
        1,
        "SSSD reports the directory backend offline: {}.",
    )
    STATUS_UNAVAILABLE = CheckInfo(
        1, "Could not determine the backend status: sssctl is unavailable or reported no status."
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that SSSD reports the directory backend (AD/LDAP) online."

    def should_run(self, context: Context) -> bool:
        """Run only when the node has an AD/LDAP integration (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Fail when SSSD reports the backend offline; skip when the status cannot be determined.

        The backend state comes from a read-only ``sssctl domain-status``. When sssctl is unavailable,
        errors, or reports no parseable status (``_sssd_backend_status`` returns None), the check cannot
        assess anything and records SKIPPED_NOT_APPLICABLE.
        """
        status = _sssd_backend_status()
        if status is None:
            return Result.skipped_not_applicable(self, infos=[self.STATUS_UNAVAILABLE])
        if status.online is False:
            return Result.failure(self, errors=[self.BACKEND_OFFLINE.format(status.summary)])
        return Result.passed(self)


class DirectoryEndpointCertificateIsValid(Check):
    """Verify the TLS certificate the directory endpoint presents validates against the configured CA.

    SSSD connects to AD/LDAP over TLS (``ldaps://``). If the server certificate does not validate, then
    with ``ldap_tls_reqcert = demand`` (SSSD's default) SSSD refuses the connection and identity lookups
    fail cluster-wide, so this check fails. With a relaxed ``reqcert`` (allow/never/try) SSSD proceeds
    despite the invalid certificate, so the check passes. It runs a read-only openssl TLS handshake.
    """

    INVALID_CERTIFICATE = CheckError(
        1,
        "The directory endpoint TLS certificate did not validate: {}. With ldap_tls_reqcert={}, SSSD "
        "refuses the connection, so identity lookups fail cluster-wide. Fix the certificate or the "
        "configured CA (ldap_tls_cacert).",
    )
    NO_TLS_ENDPOINT = CheckInfo(1, "No TLS (ldaps://) directory endpoint is configured in ldap_uri.")
    OPENSSL_UNAVAILABLE = CheckInfo(2, "openssl is not available to validate the endpoint certificate.")
    NOT_VALIDATED = CheckInfo(3, "No configured directory endpoint could be reached to validate its certificate.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the directory endpoint's TLS certificate validates against the configured CA."

    def should_run(self, context: Context) -> bool:
        """Run only when at least one configured directory endpoint uses TLS (``ldaps://``)."""
        return any(scheme == "ldaps" for _uri, _host, _port, scheme in _ldap_endpoints())

    def run(self, context: Context) -> Result:
        """Fail when a directory endpoint's TLS certificate does not validate and ``reqcert`` is strict.

        With a relaxed ``reqcert`` an invalid certificate is not flagged (SSSD proceeds anyway).
        Endpoints that cannot be reached (no handshake / no verify code) are left to
        DirectoryBackendIsReachable and do not count here; if none could be validated, or openssl is
        unavailable, the check records SKIPPED_NOT_APPLICABLE.
        """
        cacert, reqcert = _ldap_tls_settings()
        ldaps_endpoints = [(host, port) for _uri, host, port, scheme in _ldap_endpoints() if scheme == "ldaps"]
        if not ldaps_endpoints:
            return Result.skipped_not_applicable(self, infos=[self.NO_TLS_ENDPOINT])

        outcome = self._evaluate_endpoints(cacert, ldaps_endpoints)
        if outcome is None:  # openssl not installed / not on PATH
            return Result.skipped_not_applicable(self, infos=[self.OPENSSL_UNAVAILABLE])

        validated, problems = outcome
        if not problems:
            if validated:
                return Result.passed(self)
            return Result.skipped_not_applicable(self, infos=[self.NOT_VALIDATED])

        # SSSD's reqcert default is "hard" when unset; hard/demand make an invalid cert fatal.
        detail = "; ".join(problems)
        if reqcert in ("", "hard", "demand"):
            return Result.failure(self, errors=[self.INVALID_CERTIFICATE.format(detail, reqcert or "hard (default)")])
        return Result.passed(self)

    @staticmethod
    def _evaluate_endpoints(cacert, endpoints) -> Optional[Tuple[int, List[str]]]:
        """Validate each endpoint's certificate; return ``(validated_count, problems)`` or None.

        Returns None when openssl is unavailable. Endpoints that time out or show no handshake evidence
        are a reachability concern (not counted); the rest are counted, and validation failures are added
        to ``problems`` as "host:port (reason)".
        """
        validated = 0
        problems: List[str] = []
        for host, port in endpoints:
            try:
                probe = ldap.verify_tls_certificate(host, port, cacert)
            except OSError as error:  # openssl not installed / not on PATH
                logger.warning("Could not run openssl to validate %s:%s: %s", host, port, error)
                return None
            if probe.timed_out:
                continue  # could not complete the handshake: a reachability concern, not a cert one
            combined_output = "{}\n{}".format(probe.stdout, probe.stderr)
            validated_state = ldap.parse_tls_verification(combined_output)
            if validated_state is None:
                continue  # no evidence a certificate was evaluated: a reachability concern
            validated += 1
            if validated_state is False:
                problems.append("{}:{} ({})".format(host, port, ldap.tls_verify_error_reason(combined_output)))
        return validated, problems


class DirectoryBindCredentialsAreValid(Check):
    """Verify SSSD's configured bind DN and password authenticate against the directory.

    SSSD binds to AD/LDAP with ``ldap_default_bind_dn`` / ``ldap_default_authtok`` to resolve identities.
    If those credentials are wrong or expired, every lookup fails. This check reproduces the bind with a
    read-only ``ldapsearch``. It can only run when the password is stored in plaintext
    (``ldap_default_authtok_type = password``); an obfuscated token cannot be verified read-only.
    """

    INVALID_CREDENTIALS = CheckError(
        1,
        "The directory rejected SSSD's configured bind credentials (ldap_default_bind_dn / ldap_default_authtok).",
    )
    BIND_ERROR = CheckError(
        2,
        "Could not complete the directory bind to verify SSSD's credentials ({}).",
    )
    CANNOT_VERIFY = CheckInfo(
        1,
        "Cannot verify the bind: ldap_default_bind_dn/ldap_default_authtok is missing or obfuscated "
        "(only a plaintext authtok can be verified), or no ldap_uri is configured.",
    )
    LDAPSEARCH_UNAVAILABLE = CheckInfo(2, "ldapsearch is not available to verify the bind credentials.")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that SSSD's configured bind DN and password authenticate against the directory."

    def should_run(self, context: Context) -> bool:
        """Run only when the node has an AD/LDAP integration (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Fail when the configured bind DN/password is rejected; skip when it cannot be verified.

        Each configured endpoint is tried in turn: a successful bind against any of them passes, and a
        rejected credential is authoritative regardless of endpoint. Only when every endpoint fails to
        bind for another reason (unreachable / TLS) is the last such error reported.
        """
        credentials = _ldap_bind_credentials()
        endpoints = _ldap_endpoints()
        if credentials is None or not endpoints:
            return Result.skipped_not_applicable(self, infos=[self.CANNOT_VERIFY])

        bind_dn, password = credentials
        cacert, reqcert = _ldap_tls_settings()
        bind_error = None
        for uri, _host, _port, _scheme in endpoints:
            try:
                # A base-scoped search of the rootDSE exercises only the bind, and needs no search base.
                probe = ldap.ldap_bind_search(
                    uri, bind_dn, password, base="", attributes=["1.1"], cacert=cacert, reqcert=reqcert
                )
            except OSError as error:  # ldapsearch not installed / not on PATH
                logger.warning("Could not run ldapsearch to verify bind credentials: %s", error)
                return Result.skipped_not_applicable(self, infos=[self.LDAPSEARCH_UNAVAILABLE])

            if probe.succeeded:
                return Result.passed(self)
            if probe.returncode == ldap.LDAP_INVALID_CREDENTIALS_CODE:
                return Result.failure(self, errors=[self.INVALID_CREDENTIALS])
            bind_error = (
                "timed out" if probe.timed_out else "exit code {}: {}".format(probe.returncode, probe.stderr.strip())
            )
        return Result.failure(self, errors=[self.BIND_ERROR.format(bind_error)])


class DirectoryUsersResolveUnderSearchBase(Check):
    """Verify the allow-listed users are found under the configured LDAP search base.

    SSSD only resolves identities that fall under ``ldap_search_base`` (or ``ldap_user_search_base``). A
    user configured in ``simple_allow_users`` that does not appear under that base cannot log in, even
    though the endpoint and credentials are healthy, which points at a mis-scoped search base. This check
    searches the base directly with a read-only ``ldapsearch``.
    """

    USER_NOT_UNDER_BASE = CheckWarning(
        1,
        "Allow-listed user(s) not found under the configured LDAP search base '{}': {}. They are "
        "expected to resolve under the search base (ldap_search_base / ldap_user_search_base).",
    )
    CANNOT_VERIFY = CheckInfo(
        1,
        "Cannot verify search-base membership: a plaintext bind (ldap_default_bind_dn/authtok), a search "
        "base (ldap_search_base/ldap_user_search_base), an ldap_uri, and simple_allow_users are all "
        "required.",
    )
    LDAPSEARCH_UNAVAILABLE = CheckInfo(2, "ldapsearch is not available to search the configured base.")
    SEARCH_INCOMPLETE = CheckInfo(3, "A directory search could not be completed (bind or connectivity error).")

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that allow-listed users are found under the configured LDAP search base."

    def should_run(self, context: Context) -> bool:
        """Run only when the node has an AD/LDAP integration (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Warn when an allow-listed user is not found under the search base; skip when unverifiable.

        Verification needs a plaintext bind, a search base, an endpoint, and allow-listed users; when any
        is missing, or a search cannot be completed (bind/connectivity error), the check records
        SKIPPED_NOT_APPLICABLE rather than reporting a false "not found".
        """
        credentials = _ldap_bind_credentials()
        base = _ldap_search_base()
        endpoints = _ldap_endpoints()
        users = [user for user in _split_csv(_read_sssd_value("simple_allow_users")) if user not in ("root", "nobody")]
        if credentials is None or not base or not endpoints or not users:
            return Result.skipped_not_applicable(self, infos=[self.CANNOT_VERIFY])

        bind_dn, password = credentials
        cacert, reqcert = _ldap_tls_settings()
        # Try each endpoint until one yields a completable search; the membership answer is the same for
        # any healthy endpoint, so the first that completes is authoritative.
        for uri, _host, _port, _scheme in endpoints:
            try:
                missing = self._missing_users(uri, users, base, bind_dn, password, cacert, reqcert)
            except OSError as error:  # ldapsearch not installed / not on PATH
                logger.warning("Could not run ldapsearch to check the search base: %s", error)
                return Result.skipped_not_applicable(self, infos=[self.LDAPSEARCH_UNAVAILABLE])
            if missing is None:
                continue  # bind/connectivity error on this endpoint: try the next one
            if missing:
                return Result.warning(self, warnings=[self.USER_NOT_UNDER_BASE.format(base, ", ".join(missing))])
            return Result.passed(self)
        # No endpoint yielded a completable search; a bind/connectivity error is not a membership answer.
        return Result.skipped_not_applicable(self, infos=[self.SEARCH_INCOMPLETE])

    @staticmethod
    def _missing_users(uri, users, base, bind_dn, password, cacert, reqcert) -> Optional[List[str]]:
        """Return the allow-listed users not found under ``base`` via ``uri``, or None if the search fails.

        Returns an empty list when every user resolves. None means a bind/connectivity error prevented a
        conclusive answer on this endpoint (the caller then tries the next one).

        Raises:
            OSError: If the ldapsearch binary is not installed / not on PATH.
        """
        missing = []
        for user in users:
            ldap_filter = "(|(sAMAccountName={u})(uid={u})(cn={u}))".format(u=_ldap_escape(user))
            probe = ldap.ldap_bind_search(
                uri,
                bind_dn,
                password,
                base=base,
                scope="sub",
                ldap_filter=ldap_filter,
                attributes=["1.1"],
                cacert=cacert,
                reqcert=reqcert,
            )
            if not probe.succeeded:
                return None
            if "dn:" not in probe.stdout.lower():
                missing.append(user)
        return missing


def _directory_service_config(context: Context) -> Optional[dict]:
    """Return the cluster configuration's DirectoryService section, or None when it is absent."""
    return (context.cluster_config or {}).get("DirectoryService")


def _ad_integration_configured(context: Context) -> bool:
    """Return whether the node integrates a directory service.

    True when the cluster configuration declares a DirectoryService section, or when sssd.conf uses an
    LDAP/AD identity provider (covering integrations set up outside the cluster configuration).
    """
    if _directory_service_config(context):
        return True
    provider = (_read_sssd_value("id_provider") or "").strip().lower()
    return provider in ("ldap", "ad")


def _nss_slurm_enabled(context: Context) -> Optional[bool]:
    """Return whether the Slurm NSS plugin is enabled, or None when slurm.conf cannot be read.

    The plugin is active when ``enable_nss_slurm`` appears in a LaunchParameters line of slurm.conf.
    """
    path = _slurm_conf_path(context)
    try:
        content = Path(path).read_text(encoding="utf-8")
    except OSError as error:
        logger.warning("Could not read %s to check for %s: %s", path, NSS_SLURM_LAUNCH_PARAMETER, error)
        return None
    for match in re.finditer(r"(?im)^\s*LaunchParameters\s*=\s*(.*)$", content):
        if NSS_SLURM_LAUNCH_PARAMETER.lower() in match.group(1).lower():
            return True
    return False


def _ldap_endpoints() -> List[Tuple[str, str, int, str]]:
    """Return one ``(uri, host, port, scheme)`` tuple per configured ``ldap_uri`` (space/comma separated)."""
    endpoints = []
    for token in re.split(r"[,\s]+", (_read_sssd_value("ldap_uri") or "").strip()):
        if not token:
            continue
        parts = urllib.parse.urlsplit(token)
        if not parts.hostname:
            continue
        scheme = (parts.scheme or "ldap").lower()
        port = parts.port or (636 if scheme == "ldaps" else 389)
        endpoints.append((token, parts.hostname, port, scheme))
    return endpoints


def _ldap_tls_settings() -> Tuple[Optional[str], str]:
    """Return ``(ldap_tls_cacert, ldap_tls_reqcert)`` from sssd.conf; reqcert lower-cased ('' if unset)."""
    return _read_sssd_value("ldap_tls_cacert"), (_read_sssd_value("ldap_tls_reqcert") or "").strip().lower()


def _ldap_bind_credentials() -> Optional[Tuple[str, str]]:
    """Return ``(bind_dn, password)`` when a verifiable plaintext bind is configured, else None.

    Returns None when the bind DN or authtok is missing, or the authtok is obfuscated
    (``ldap_default_authtok_type`` other than ``password``), which cannot be verified read-only.
    """
    bind_dn = _read_sssd_value("ldap_default_bind_dn")
    authtok = _read_sssd_value("ldap_default_authtok")
    authtok_type = (_read_sssd_value("ldap_default_authtok_type") or "password").strip().lower()
    if not bind_dn or not authtok or authtok_type != "password":
        return None
    return bind_dn, authtok


def _ldap_search_base() -> Optional[str]:
    """Return the LDAP user search base: ``ldap_user_search_base`` if set, else ``ldap_search_base``."""
    return _read_sssd_value("ldap_user_search_base") or _read_sssd_value("ldap_search_base")


def _ldap_escape(value: str) -> str:
    """Escape the RFC 4515 special characters in an LDAP filter assertion value."""
    escaped = []
    for char in value:
        if char in "\\*()\0":
            escaped.append("\\{:02x}".format(ord(char)))
        else:
            escaped.append(char)
    return "".join(escaped)


def _cache_credentials_enabled() -> bool:
    """Return whether SSSD credential caching is enabled (cache_credentials truthy in sssd.conf).

    Absent or unreadable defaults to disabled, matching SSSD's own default for cache_credentials.
    """
    return (_read_sssd_value("cache_credentials") or "").strip().lower() in ("true", "yes", "1", "on")


def _slurm_conf_path(context: Context) -> str:
    """Return the slurm.conf path derived from the Slurm install dir in dna.json (or the default)."""
    install_dir = (((context.dna_json or {}).get("cluster") or {}).get("slurm") or {}).get(
        "install_dir"
    ) or DEFAULT_SLURM_INSTALL_DIR
    return "{}/{}".format(install_dir.rstrip("/"), SLURM_CONF_RELATIVE_PATH)


def _ad_domain_names() -> List[str]:
    """Return the sssd.conf domain names configured with an LDAP/AD ``id_provider``.

    Each SSSD domain lives in a ``[domain/<name>]`` section; only those backed by ``ldap``/``ad`` are
    directory integrations (the ``files``-backed local domain is skipped). Missing/unparseable sssd.conf
    yields an empty list.
    """
    parser = _load_sssd_parser()
    if parser is None:
        return []
    names = []
    for section in parser.sections():
        if section.startswith("domain/"):
            provider = (parser.get(section, "id_provider", fallback="") or "").strip().lower()
            if provider in ("ldap", "ad"):
                names.append(section.split("/", 1)[1])
    return names


def _sssd_backend_status() -> Optional[SssdBackendStatus]:
    """Return a read-only ``sssctl domain-status`` snapshot of the AD/LDAP domain(s), or None."""
    summaries = []
    online_flags = []
    for domain in _ad_domain_names():
        try:
            timed = time_command(["sssctl", "domain-status", domain], timeout=DIRECTORY_LOOKUP_COMMAND_TIMEOUT_SECONDS)
        except OSError as error:  # sssctl not installed / not on PATH
            logger.warning("Could not run 'sssctl domain-status %s': %s", domain, error)
            continue
        if timed.timed_out or timed.returncode != 0:
            continue
        compact = "; ".join(line.strip() for line in timed.stdout.splitlines() if line.strip())
        if not compact:
            continue
        summaries.append("{}: {}".format(domain, compact))
        online_flags.append(_parse_online_status(timed.stdout))

    if not summaries:
        return None
    if False in online_flags:
        online: Optional[bool] = False
    elif online_flags and all(flag is True for flag in online_flags):
        online = True
    else:
        online = None
    return SssdBackendStatus(summary=" | ".join(summaries), online=online)


def _parse_online_status(status_output: str) -> Optional[bool]:
    """Return the backend online state from an ``sssctl domain-status`` output, or None if not reported.

    ``sssctl`` prints an ``Online status: Online|Offline`` line; True/False is derived from it.
    """
    for line in status_output.splitlines():
        stripped = line.strip().lower()
        if stripped.startswith("online status:"):
            value = stripped.split(":", 1)[1]
            if "offline" in value:
                return False
            if "online" in value:
                return True
    return None


def _load_sssd_parser() -> Optional[configparser.ConfigParser]:
    """Parse sssd.conf and return the ConfigParser, or None when it cannot be read/parsed.

    interpolation=None so values containing '%' (e.g. SSSD's '/home/%u') are returned verbatim.
    """
    parser = configparser.ConfigParser(interpolation=None)
    try:
        with open(SSSD_CONF_PATH, "r", encoding="utf-8") as handle:
            parser.read_file(handle)
    except (OSError, configparser.Error) as error:
        logger.warning("Could not read %s: %s", SSSD_CONF_PATH, error)
        return None
    return parser


def _read_sssd_value(key: str) -> Optional[str]:
    """Return the first value for ``key`` found in any section of sssd.conf, or None."""
    parser = _load_sssd_parser()
    if parser is None:
        return None
    for section in parser.sections():
        if parser.has_option(section, key):
            return parser.get(section, key)
    return None


def _principal_from_dn(value: Optional[str]) -> Optional[str]:
    """Return the lookup name for ``value``: the CN component of a DN, or the value itself otherwise."""
    if not value:
        return None
    value = value.strip()
    match = re.match(r"(?i)CN=([^,]+)", value)
    if match:
        return match.group(1).strip()
    return value or None


def _split_csv(value: Optional[str]) -> List[str]:
    """Split a comma-separated SSSD value into a list of trimmed, non-empty tokens."""
    if not value:
        return []
    return [token.strip() for token in value.split(",") if token.strip()]
