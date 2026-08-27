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

"""Slurm accounting config resolution, secret handling, redaction, and the read-only mysql probe."""

import json
import logging
import os
import subprocess  # nosec B404  # used only for subprocess.TimeoutExpired; execution goes through shell.run_command
import tempfile
from dataclasses import dataclass
from typing import Dict, Optional, Tuple

import boto3
from botocore.exceptions import ClientError

from pcluster_diag.core.constants import (
    DEFAULT_DATABASE_PORT,
    DEFAULT_SLURMDBD_PORT,
    SCONTROL_PATH,
    SLURM_PARALLELCLUSTER_SLURMDBD_CONF_PATH,
    SLURMDBD_CONF_PATH,
)
from pcluster_diag.models.context import Context
from pcluster_diag.util import shell

logger = logging.getLogger(__name__)

LOCAL_SLURMDBD_HOST = "localhost"
_ACCOUNTING_STORAGE_PORT_KEY = "AccountingStoragePort"
_ACCOUNTING_STORAGE_HOST_KEY = "AccountingStorageHost"
_ACCOUNTING_STORAGE_TYPE_KEY = "AccountingStorageType"
_ACCOUNTING_STORAGE_SLURMDBD_VALUE = "accounting_storage/slurmdbd"
_SCONTROL_CONFIG_TIMEOUT_SECONDS = 10


# --- Config resolution -------------------------------------------------------------


@dataclass(frozen=True)
class AccountingConfig:
    """Resolved Slurm accounting configuration derived from ``Context`` and the on-disk conf files.

    In ExternalSlurmdbd mode the database, its credentials, and the local slurmdbd configuration files
    all live on a separate instance the head node cannot inspect, so every database-related field is
    ``None`` and only the slurmdbd endpoint (``slurmdbd_host``/``slurmdbd_port``) is populated.

    Attributes:
        is_external: ``True`` when ``Scheduling.SlurmSettings.ExternalSlurmdbd`` is declared.
        slurmdbd_host: The head node (``localhost``) in Local_Slurmdbd mode, else ``ExternalSlurmdbd.Host``.
        slurmdbd_port: The slurmdbd listening port -- ``slurm.conf`` ``AccountingStoragePort``
            (default ``6819``) in Local_Slurmdbd mode, else ``ExternalSlurmdbd.Port``.
        db_host: The Accounting_Database host parsed from ``Database.Uri`` (``None`` when external).
        db_port: The Accounting_Database port parsed from ``Database.Uri`` (default ``3306``; ``None``
            when external).
        db_user: ``Database.UserName`` (``None`` when external).
        db_name: The accounting database name (``StorageLoc``): ``Database.DatabaseName`` when set,
            otherwise the cluster name with each ``-`` replaced by ``_`` (``None`` when external).
        password_secret_arn: ``Database.PasswordSecretArn`` (``None`` when external).
        region: The AWS region the cluster runs in.
    """

    is_external: bool
    slurmdbd_host: Optional[str]
    slurmdbd_port: Optional[int]
    db_host: Optional[str]
    db_port: Optional[int]
    db_user: Optional[str]
    db_name: Optional[str]
    password_secret_arn: Optional[str]
    region: Optional[str]


def resolve_accounting_config(context: Context) -> AccountingConfig:
    """Resolve the accounting endpoints and credential references from ``context`` and conf files.

    Branches on topology, reading ``Scheduling.SlurmSettings.{Database, ExternalSlurmdbd}`` from
    ``context.cluster_config`` and setting ``is_external`` iff ``ExternalSlurmdbd`` is declared:

    When the cluster configuration declares neither ``Database`` nor ``ExternalSlurmdbd`` (accounting
    was configured outside ParallelCluster's management), the configuration cannot supply the endpoints
    or credentials, so they are derived from Slurm's own state instead (see
    :func:`_resolve_from_slurm`). This keeps the database-facing probes meaningful for out-of-band
    accounting rather than silently no-op'ing on all-``None`` fields.
    """
    slurm_settings = _slurm_settings(context)
    database = slurm_settings.get("Database")
    external = slurm_settings.get("ExternalSlurmdbd")
    region = _region(context)

    if external is not None:
        return AccountingConfig(
            is_external=True,
            slurmdbd_host=external.get("Host"),
            slurmdbd_port=_parse_port(external.get("Port")),
            db_host=None,
            db_port=None,
            db_user=None,
            db_name=None,
            password_secret_arn=None,
            region=region,
        )

    if database is None:
        # Neither topology declared in the cluster config: accounting is running outside
        # ParallelCluster's management. Derive what we can from Slurm's own configuration.
        return _resolve_from_slurm(context, region)

    db_host, db_port = parse_db_uri(database.get("Uri"))
    if db_host is not None and db_port is None:
        db_port = DEFAULT_DATABASE_PORT

    return AccountingConfig(
        is_external=False,
        slurmdbd_host=LOCAL_SLURMDBD_HOST,
        slurmdbd_port=_local_slurmdbd_port(),
        db_host=db_host,
        db_port=db_port,
        db_user=database.get("UserName"),
        db_name=_accounting_db_name(context, database),
        password_secret_arn=database.get("PasswordSecretArn"),
        region=region,
    )


def _resolve_from_slurm(context: Context, region: Optional[str]) -> AccountingConfig:
    """Resolve accounting endpoints and credentials from Slurm's own state (out-of-band accounting)."""
    conf = read_slurmdbd_conf()
    if conf:
        db_host = conf.get("StorageHost")
        db_port = _parse_port(conf.get("StoragePort"))
        if db_host is not None and db_port is None:
            db_port = DEFAULT_DATABASE_PORT
        return AccountingConfig(
            is_external=False,
            slurmdbd_host=LOCAL_SLURMDBD_HOST,
            slurmdbd_port=_local_slurmdbd_port(),
            db_host=db_host,
            db_port=db_port,
            db_user=conf.get("StorageUser"),
            db_name=conf.get("StorageLoc") or _default_db_name(context),
            password_secret_arn=None,
            region=region,
        )

    scontrol = _scontrol_config()
    return AccountingConfig(
        is_external=True,
        slurmdbd_host=scontrol.get(_ACCOUNTING_STORAGE_HOST_KEY),
        slurmdbd_port=_parse_port(scontrol.get(_ACCOUNTING_STORAGE_PORT_KEY)) or DEFAULT_SLURMDBD_PORT,
        db_host=None,
        db_port=None,
        db_user=None,
        db_name=None,
        password_secret_arn=None,
        region=region,
    )


def accounting_declared_in_config(context: Context) -> bool:
    """Return whether Slurm accounting is declared in the cluster configuration."""
    slurm_settings = _slurm_settings(context)
    return slurm_settings.get("Database") is not None or slurm_settings.get("ExternalSlurmdbd") is not None


def accounting_present_on_node() -> bool:
    """Return whether the running Slurm controller has the slurmdbd accounting backend enabled."""
    storage_type = _scontrol_config().get(_ACCOUNTING_STORAGE_TYPE_KEY, "")
    return storage_type.strip().lower() == _ACCOUNTING_STORAGE_SLURMDBD_VALUE


def _scontrol_config() -> Dict[str, str]:
    """Return the effective Slurm configuration reported by ``scontrol show config`` as a key/value map."""
    try:
        result = shell.run_command([SCONTROL_PATH, "show", "config"], timeout=_SCONTROL_CONFIG_TIMEOUT_SECONDS)
    except OSError as error:
        logger.info("Could not run 'scontrol show config': %s", error)
        return {}
    if result.returncode != 0:
        logger.info("'scontrol show config' exited %s: %s", result.returncode, result.stderr.strip())
        return {}
    values: Dict[str, str] = {}
    for line in result.stdout.splitlines():
        if "=" not in line:
            continue
        key, _, value = line.partition("=")
        values[key.strip()] = value.strip()
    return values


def read_slurmdbd_conf() -> Dict[str, str]:
    """Return the merged on-disk slurmdbd configuration as a key/value map."""
    merged: Dict[str, str] = {}
    for path in (SLURMDBD_CONF_PATH, SLURM_PARALLELCLUSTER_SLURMDBD_CONF_PATH):
        try:
            merged.update(parse_keyvalue_conf(path))
        except OSError:
            continue
    return merged


def parse_keyvalue_conf(path: str) -> Dict[str, str]:
    """Parse a ``key=value`` Slurm conf file, treating ``#`` as the start of a comment."""
    values: Dict[str, str] = {}
    with open(path, "r", encoding="utf-8") as conf_file:
        for line in conf_file:
            # A '#' begins a comment; keep only the content before it.
            content = line.split("#", 1)[0].strip()
            if not content or "=" not in content:
                continue
            key, _, value = content.partition("=")
            values[key.strip()] = value.strip()
    return values


def parse_db_uri(uri: Optional[str]) -> Tuple[Optional[str], Optional[int]]:
    """Split a ``Database.Uri`` value into ``(host, port)``."""
    if not uri:
        return None, None
    if ":" in uri:
        host, _, port_str = uri.partition(":")
        host = host or None
        try:
            return host, int(port_str)
        except ValueError:
            logger.warning("Could not parse port from Database.Uri %r; treating port as unset", uri)
            return host, None
    return uri, None


# --- Secret retrieval --------------------------------------------------------------


class SecretAccessDenied(Exception):
    """Raised when the instance role lacks permission to read the accounting password secret.

    Maps the Secrets Manager ``AccessDenied``/``AccessDeniedException`` error codes (missing
    ``secretsmanager:GetSecretValue`` or ``secretsmanager:DescribeSecret`` permission).
    """


class SecretNotFound(Exception):
    """Raised when the accounting password secret does not exist.

    Maps the Secrets Manager ``ResourceNotFoundException`` error code.
    """


# Secrets Manager error codes that translate to the exceptions above.
_SECRET_ACCESS_DENIED_CODES = frozenset({"AccessDenied", "AccessDeniedException"})
_SECRET_NOT_FOUND_CODES = frozenset({"ResourceNotFoundException"})


def get_secret_string(arn: str, region: str) -> str:
    """Return the ``SecretString`` of the Secrets Manager secret ``arn`` in ``region``."""
    client = boto3.client("secretsmanager", region_name=region)
    try:
        response = client.get_secret_value(SecretId=arn)
    except ClientError as error:
        code = error.response.get("Error", {}).get("Code")
        if code in _SECRET_ACCESS_DENIED_CODES:
            raise SecretAccessDenied(arn) from error
        if code in _SECRET_NOT_FOUND_CODES:
            raise SecretNotFound(arn) from error
        raise
    return response["SecretString"]


def secret_is_json_object(secret: str) -> bool:
    """Return ``True`` iff ``secret`` parses as a JSON object (dict), else ``False`` (Requirement 6.3)."""
    try:
        parsed = json.loads(secret)
    except (ValueError, TypeError):
        return False
    return isinstance(parsed, dict)


# --- Redaction -----------------------------------------------------

REDACTION_PLACEHOLDER = "***REDACTED***"


def redact(text: str, secret: Optional[str]) -> str:
    """Return ``text`` with every occurrence of ``secret`` replaced by :data:`REDACTION_PLACEHOLDER`."""
    if not secret:
        return text
    return text.replace(secret, REDACTION_PLACEHOLDER)


def contains_reserved_comment_char(password: Optional[str]) -> bool:
    """Return ``True`` iff ``password`` contains the ``#`` comment character."""
    if password is None:
        return False
    return "#" in password


# --- Read-only mysql client probe --------------------------------------------------


@dataclass
class MysqlProbeResult:
    """Outcome of a single read-only ``mysql`` CLI probe.

    The probe never mutates state: it runs one read-only statement (from the caller's allow-list, e.g.
    ``SELECT 1`` or ``SHOW GRANTS FOR CURRENT_USER()``) and reports how the client exited. Both
    ``stdout`` and ``stderr`` are already passed through :func:`redact` by :func:`mysql_probe`, so no
    field of this object can contain the database password (Requirements 4.1, 4.2).

    Attributes:
        returncode: The ``mysql`` client exit code, or ``None`` when the probe timed out.
        stdout: The captured standard output, already redacted of the password.
        stderr: The captured standard error, already redacted of the password.
        timed_out: ``True`` when the probe exceeded ``timeout`` and was killed (Requirement 3.5/6.6).
    """

    returncode: Optional[int]
    stdout: str
    stderr: str
    timed_out: bool

    @property
    def succeeded(self) -> bool:
        """Return whether the probe completed with a zero exit code (and did not time out)."""
        return self.returncode == 0 and not self.timed_out


MYSQL_ACCESS_DENIED_CODE = 1045  # invalid credentials
MYSQL_DB_ACCESS_DENIED_CODE = 1044  # access denied to a named database


def mysql_probe(
    host: str,
    port: int,
    user: str,
    password: str,
    database: Optional[str],
    sql: str,
    timeout: int,
    secret_for_redaction: Optional[str] = None,
) -> MysqlProbeResult:
    """Run a single read-only ``mysql`` statement without ever placing the password on the command line.

    The invoked command is::

        mysql --defaults-extra-file=<tmp> [--connect-timeout=<timeout>] [database] -N -B -e "<sql>"
    """
    redaction_secret = secret_for_redaction or password
    # mkstemp atomically creates the file with mode 0600 (owner-only), so the credentials are never
    # briefly readable by other users. It returns an open fd plus the path.
    fd, tmp_path = tempfile.mkstemp(prefix="pcluster-diag-mysql-", suffix=".cnf")
    try:
        _write_defaults_extra_file(fd, host, port, user, password)
        argv = ["mysql", "--defaults-extra-file={}".format(tmp_path)]
        if timeout:
            argv.append("--connect-timeout={}".format(timeout))
        if database is not None:
            argv.append(database)
        argv += ["-N", "-B", "-e", sql]
        try:
            result = shell.run_command(argv, timeout=timeout)
        except subprocess.TimeoutExpired as error:
            return MysqlProbeResult(
                returncode=None,
                stdout="",
                stderr=redact(_as_text(error.stderr), redaction_secret),
                timed_out=True,
            )
        return MysqlProbeResult(
            returncode=result.returncode,
            stdout=redact(result.stdout, redaction_secret),
            stderr=redact(result.stderr, redaction_secret),
            timed_out=False,
        )
    finally:
        # Always remove the temp file so no secret is left on disk (Requirement 3.6).
        if os.path.exists(tmp_path):
            os.unlink(tmp_path)


def _write_defaults_extra_file(fd: int, host: str, port: int, user: str, password: str) -> None:
    """Write the ``[client]`` credentials into the already-0600 file descriptor."""
    with os.fdopen(fd, "w", encoding="utf-8") as defaults_file:
        defaults_file.write(
            "[client]\nhost={}\nport={}\nuser={}\npassword={}\n".format(host, port, user, quote_option_value(password))
        )


def quote_option_value(value: str) -> str:
    """Return ``value`` quoted for a MySQL option file, so reserved characters survive verbatim."""
    escaped = value.replace("\\", "\\\\").replace('"', '\\"')
    return '"{}"'.format(escaped)


def _as_text(output) -> str:
    """Normalize captured output (which may be ``None`` or ``bytes`` on timeout) to a string."""
    if output is None:
        return ""
    if isinstance(output, bytes):
        return output.decode("utf-8", errors="replace")
    return output


# --- Internal helpers --------------------------------------------------------------


def _slurm_settings(context: Context) -> dict:
    """Return the ``Scheduling.SlurmSettings`` section of the cluster config, or an empty dict."""
    scheduling = (context.cluster_config or {}).get("Scheduling") or {}
    return scheduling.get("SlurmSettings") or {}


def _region(context: Context) -> Optional[str]:
    """Return the AWS region from ``dna.json`` (``cluster.region``), falling back to the cluster config."""
    region = (((context.dna_json or {}).get("cluster")) or {}).get("region")
    if region:
        return region
    return (context.cluster_config or {}).get("Region")


def _cluster_name(context: Context) -> Optional[str]:
    """Return the cluster name from ``dna.json`` (``cluster.cluster_name``, else ``cluster.stack_name``)."""
    cluster = ((context.dna_json or {}).get("cluster")) or {}
    return cluster.get("cluster_name") or cluster.get("stack_name")


def _accounting_db_name(context: Context, database: dict) -> Optional[str]:
    """Return the accounting database name (``StorageLoc``).

    Uses ``Database.DatabaseName`` when set, otherwise the cluster name with each ``-`` replaced by
    ``_`` (ParallelCluster's default ``StorageLoc``). Returns ``None`` when neither is available.
    """
    database_name = database.get("DatabaseName")
    if database_name:
        return database_name
    return _default_db_name(context)


def _default_db_name(context: Context) -> Optional[str]:
    """Return ParallelCluster's default accounting database name: the cluster name with ``-`` -> ``_``."""
    cluster_name = _cluster_name(context)
    if cluster_name:
        return cluster_name.replace("-", "_")
    return None


def _local_slurmdbd_port() -> int:
    """Return the local slurmdbd listening port from the effective ``AccountingStoragePort``."""
    port = _parse_port(_scontrol_config().get(_ACCOUNTING_STORAGE_PORT_KEY))
    return port if port is not None else DEFAULT_SLURMDBD_PORT


def _parse_port(value) -> Optional[int]:
    """Parse a port value (which may be a string from a conf file) to an int, or ``None`` if invalid."""
    if value is None:
        return None
    try:
        return int(value)
    except (TypeError, ValueError):
        logger.warning("Ignoring non-integer port value %r", value)
        return None
