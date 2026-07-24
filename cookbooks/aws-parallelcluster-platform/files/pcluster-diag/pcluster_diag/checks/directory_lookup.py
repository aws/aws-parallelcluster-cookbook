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

"""A Check diagnosing the directory service (NSS -> SSSD -> LDAP/AD) integration.

slurmctld resolves users and groups through NSS on its main control thread (e.g. AllowGroups refresh,
job credential creation). When those lookups are slow, the controller's periodic loop is delayed, node
pings are missed, and healthy compute nodes can be marked DOWN/NOT_RESPONDING and recycled. This module
provides:

- lookup latency: times the exact NSS calls slurmctld depends on (``getent group``, ``getent passwd``,
  ``id``) and flags lookups slow enough to put the controller at risk;
- managed-by-cluster-config: warns when an AD/LDAP integration exists on the node but is not declared in
  the cluster configuration (so ParallelCluster cannot manage or validate it);
- resiliency settings: warns when the settings that reduce directory-lookup load (the Slurm NSS plugin
  and SSSD credential caching) are not enabled;
- backend reachability: consults a read-only ``sssctl domain-status`` and fails when SSSD reports the
  directory backend offline;
- endpoint certificate: runs a read-only openssl TLS handshake and fails when the directory endpoint's
  certificate does not validate against the configured CA;
- bind credentials: reproduces SSSD's bind with a read-only ``ldapsearch`` to verify the configured bind
  DN and password;
- search-base membership: searches the configured LDAP base (read-only ``ldapsearch``) to confirm the
  allow-listed users resolve under it.

All probes are read-only and safe to run on a production node. A probe whose sub-feature is simply not
enabled (e.g. no ``ldaps://`` endpoint to validate, no allow-listed users) contributes nothing. A probe
that is relevant but cannot reach a verdict because a required tool is unavailable (openssl / ldapsearch /
sssctl not installed) contributes a WARNING so the coverage gap is visible.
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
from pcluster_diag.core.probe import run_probe
from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckWarning
from pcluster_diag.models.result import Result
from pcluster_diag.models.sssd_backend_status import SssdBackendStatus
from pcluster_diag.util import ldap
from pcluster_diag.util.shell import time_command

logger = logging.getLogger(__name__)

_STATUS_OK = "ok"
_STATUS_WARN = "warn"
_STATUS_FAIL = "fail"


class DirectoryService(Check):
    """Diagnose the directory service (NSS/SSSD/AD) integration."""

    LOOKUP_SLOW_OR_FAILING = CheckError(
        1,
        "Directory lookups are slow or failing: {}. They are expected to resolve quickly and reliably.",
    )
    BACKEND_OFFLINE = CheckError(2, "SSSD reports the directory backend offline: {}.")
    CERTIFICATE_INVALID = CheckError(
        3,
        "The directory endpoint TLS certificate did not validate: {}. With ldap_tls_reqcert={}, SSSD "
        "refuses the connection, so identity lookups fail cluster-wide. Fix the certificate or the "
        "configured CA (ldap_tls_cacert).",
    )
    BIND_CREDENTIALS_INVALID = CheckError(
        4,
        "The directory rejected SSSD's configured bind credentials (ldap_default_bind_dn / ldap_default_authtok).",
    )
    BIND_ERROR = CheckError(5, "Could not complete the directory bind to verify SSSD's credentials ({}).")

    # --- Warnings (advisories and coverage gaps that do not by themselves break identity) ------
    LOOKUP_ELEVATED = CheckWarning(
        1,
        "Directory lookups are elevated or unresolved: {}. They are expected to resolve quickly and reliably.",
    )
    AD_NOT_MANAGED_BY_CLUSTER_CONFIG = CheckWarning(
        2,
        "An Active Directory integration is configured in {} but the cluster configuration has no "
        "DirectoryService section.",
    )
    NSS_SLURM_PLUGIN_DISABLED = CheckWarning(
        3,
        "The Slurm NSS plugin is not enabled ({} is absent from LaunchParameters in slurm.conf); it is "
        "expected to be enabled to reduce directory-lookup load on compute nodes.",
    )
    SSSD_CACHE_CREDENTIALS_DISABLED = CheckWarning(
        4,
        "SSSD credential caching is not enabled (cache_credentials is not set to True in {}); it is "
        "expected to be enabled so SSSD can serve cached identities when the backend is slow or briefly "
        "unavailable.",
    )
    USER_NOT_UNDER_SEARCH_BASE = CheckWarning(
        5,
        "Allow-listed user(s) not found under the configured LDAP search base '{}': {}. They are "
        "expected to resolve under the search base (ldap_search_base / ldap_user_search_base).",
    )
    BACKEND_STATUS_UNAVAILABLE = CheckWarning(
        6, "Could not determine the directory backend status: sssctl is unavailable or reported no status."
    )
    CERTIFICATE_NOT_VALIDATED = CheckWarning(
        7,
        "Could not validate the directory endpoint TLS certificate: openssl is not available.",
    )
    BIND_LDAPSEARCH_UNAVAILABLE = CheckWarning(
        8, "Could not verify the directory bind credentials: ldapsearch is not available."
    )
    SEARCH_BASE_LDAPSEARCH_UNAVAILABLE = CheckWarning(
        9, "Could not check the LDAP search base: ldapsearch is not available."
    )

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the directory service (NSS/SSSD/AD) integration is healthy."

    def should_run(self, context: Context) -> bool:
        """Run only when the node integrates a directory service (via cluster config or sssd.conf)."""
        return _ad_integration_configured(context)

    def run(self, context: Context) -> Result:
        """Run every directory probe in isolation, accumulate findings, and derive the aggregate Result."""
        errors: List[CheckError] = []
        warnings: List[CheckWarning] = []

        probes = (
            ("directory-service management", lambda: self._probe_managed_by_cluster_config(context, warnings)),
            ("resiliency settings", lambda: self._probe_resiliency_settings(context, warnings)),
            ("lookup latency", lambda: self._probe_lookup_latency(context, errors, warnings)),
            ("backend reachability", lambda: self._probe_backend_reachable(errors, warnings)),
            ("endpoint certificate", lambda: self._probe_endpoint_certificate(errors, warnings)),
            ("bind credentials", lambda: self._probe_bind_credentials(errors, warnings)),
            ("search-base membership", lambda: self._probe_users_under_search_base(warnings)),
        )
        for label, probe in probes:
            run_probe(label, probe, errors)

        return Result.from_findings(self, errors=errors, warnings=warnings)

    # --- Probes -------------------------------------------------------------------------------

    def _probe_managed_by_cluster_config(self, context: Context, warnings: List[CheckWarning]) -> None:
        """Warn when the AD/LDAP integration exists on the node but is not declared in the cluster config."""
        if _directory_service_config(context):
            return
        warnings.append(self.AD_NOT_MANAGED_BY_CLUSTER_CONFIG.format(SSSD_CONF_PATH))

    def _probe_resiliency_settings(self, context: Context, warnings: List[CheckWarning]) -> None:
        """Warn when the Slurm NSS plugin or SSSD credential caching (which reduce lookup load) is disabled."""
        if _nss_slurm_enabled(context) is False:
            warnings.append(self.NSS_SLURM_PLUGIN_DISABLED.format(NSS_SLURM_LAUNCH_PARAMETER))
        if not _cache_credentials_enabled():
            warnings.append(self.SSSD_CACHE_CREDENTIALS_DISABLED.format(SSSD_CONF_PATH))

    def _probe_lookup_latency(self, context: Context, errors: List[CheckError], warnings: List[CheckWarning]) -> None:
        """Time getent/id lookups; fail on slow/timed-out lookups, warn on elevated latency or non-resolution.

        When no lookup targets can be derived, the check does not apply.
        """
        groups, users = self._derive_targets(context)
        if not groups and not users:
            return

        probes = []
        for group in groups:
            probes.append(self._classify_lookup(["getent", "group", group], "getent group {}".format(group)))
        for user in users:
            probes.append(self._classify_lookup(["getent", "passwd", user], "getent passwd {}".format(user)))
            probes.append(self._classify_lookup(["id", user], "id {}".format(user)))

        failures = [text for status, text in probes if status == _STATUS_FAIL]
        if failures:
            errors.append(self.LOOKUP_SLOW_OR_FAILING.format("; ".join(failures)))
            return

        elevated = [text for status, text in probes if status == _STATUS_WARN]
        if elevated:
            warnings.append(self.LOOKUP_ELEVATED.format("; ".join(elevated)))

    def _probe_backend_reachable(self, errors: List[CheckError], warnings: List[CheckWarning]) -> None:
        """Fail when SSSD reports the backend offline; warn when the status cannot be determined.

        A ``getent``/``id`` lookup can be served from the SSSD cache, so passing latency does not prove the
        backend is reachable. This consults SSSD directly (``sssctl domain-status``). When sssctl is
        unavailable or reports no parseable status, the backend cannot be assessed, so it warns.
        """
        status = _sssd_backend_status()
        if status is None:
            warnings.append(self.BACKEND_STATUS_UNAVAILABLE)
            return
        if status.online is False:
            errors.append(self.BACKEND_OFFLINE.format(status.summary))

    def _probe_endpoint_certificate(self, errors: List[CheckError], warnings: List[CheckWarning]) -> None:
        """Fail when a directory endpoint's TLS certificate does not validate and ``reqcert`` is strict.

        Contributes nothing when no ``ldaps://`` endpoint is configured.
        """
        cacert, reqcert = _ldap_tls_settings()
        ldaps_endpoints = [(host, port) for _uri, host, port, scheme in _ldap_endpoints() if scheme == "ldaps"]
        if not ldaps_endpoints:
            return

        outcome = self._evaluate_endpoints(cacert, ldaps_endpoints)
        if outcome is None:  # openssl not installed / not on PATH
            warnings.append(self.CERTIFICATE_NOT_VALIDATED)
            return

        _validated, problems = outcome
        if not problems:
            return

        # SSSD's reqcert default is "hard" when unset; hard/demand make an invalid cert fatal.
        if reqcert in ("", "hard", "demand"):
            detail = "; ".join(problems)
            errors.append(self.CERTIFICATE_INVALID.format(detail, reqcert or "hard (default)"))

    def _probe_bind_credentials(self, errors: List[CheckError], warnings: List[CheckWarning]) -> None:
        """Fail when the configured bind DN/password is rejected; warn when ldapsearch is unavailable.

        Contributes nothing when no verifiable plaintext bind is configured (missing or obfuscated
        authtok) or no endpoint is configured. A rejected credential is authoritative regardless of
        endpoint; only when every endpoint fails to bind for another reason is the last such error a
        failure.
        """
        credentials = _ldap_bind_credentials()
        endpoints = _ldap_endpoints()
        if credentials is None or not endpoints:
            return

        bind_dn, password = credentials
        cacert, reqcert = _ldap_tls_settings()
        bind_error = None
        for uri, _host, _port, _scheme in endpoints:
            try:
                probe = ldap.ldap_bind_search(
                    uri, bind_dn, password, base="", attributes=["1.1"], cacert=cacert, reqcert=reqcert
                )
            except OSError as error:  # ldapsearch not installed / not on PATH
                logger.warning("Could not run ldapsearch to verify bind credentials: %s", error)
                warnings.append(self.BIND_LDAPSEARCH_UNAVAILABLE)
                return

            if probe.succeeded:
                return
            if probe.returncode == ldap.LDAP_INVALID_CREDENTIALS_CODE:
                errors.append(self.BIND_CREDENTIALS_INVALID)
                return
            bind_error = (
                "timed out" if probe.timed_out else "exit code {}: {}".format(probe.returncode, probe.stderr.strip())
            )
        errors.append(self.BIND_ERROR.format(bind_error))

    def _probe_users_under_search_base(self, warnings: List[CheckWarning]) -> None:
        """Warn when an allow-listed user is not found under the configured LDAP search base.

        Contributes nothing when the search cannot be set up (no plaintext bind, search base, endpoint, or
        allow-listed users) or when no endpoint yields a completable search (a bind/connectivity concern
        reported by the bind/backend probes). Warns when ldapsearch is unavailable.
        """
        credentials = _ldap_bind_credentials()
        base = _ldap_search_base()
        endpoints = _ldap_endpoints()
        users = [user for user in _split_csv(_read_sssd_value("simple_allow_users")) if user not in ("root", "nobody")]
        if credentials is None or not base or not endpoints or not users:
            return

        bind_dn, password = credentials
        cacert, reqcert = _ldap_tls_settings()
        for uri, _host, _port, _scheme in endpoints:
            try:
                missing = self._missing_users(uri, users, base, bind_dn, password, cacert, reqcert)
            except OSError as error:  # ldapsearch not installed / not on PATH
                logger.warning("Could not run ldapsearch to check the search base: %s", error)
                warnings.append(self.SEARCH_BASE_LDAPSEARCH_UNAVAILABLE)
                return
            if missing is None:
                continue  # bind/connectivity error on this endpoint: try the next one
            if missing:
                warnings.append(self.USER_NOT_UNDER_SEARCH_BASE.format(base, ", ".join(missing)))
            return

    # --- Probe helpers ------------------------------------------------------------------------

    def _classify_lookup(self, command: List[str], label: str) -> Tuple[str, str]:
        """Run one timed lookup and return ``(status, text)`` classified against the latency thresholds.

        ``status`` is one of the ``_STATUS_*`` tokens; ``text`` is a human-readable "``label (detail)``"
        summary used verbatim in the finding message.
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
        latency probe can still run. Missing/unparseable sources yield empty lists.
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
