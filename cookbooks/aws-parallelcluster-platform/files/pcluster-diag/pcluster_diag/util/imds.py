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

"""Helpers for querying the EC2 Instance Metadata Service."""

import urllib.error
import urllib.request
from typing import Optional

from retrying import RetryError, retry

from pcluster_diag.util.shell import run_command

# The ImdsSupport values used in the cluster configuration (see the ParallelCluster schema).
IMDS_V1 = "v1.0"  # HttpTokens optional: IMDSv1 (token-less) requests are allowed.
IMDS_V2 = "v2.0"  # HttpTokens required: only token-backed IMDSv2 requests are allowed.

_BASE_URL = "http://169.254.169.254/latest"  # nosec B104  link-local IMDS endpoint
_TOKEN_URL = _BASE_URL + "/api/token"
_INSTANCE_ID_URL = _BASE_URL + "/meta-data/instance-id"
_INSTANCE_TYPE_URL = _BASE_URL + "/meta-data/instance-type"
_METADATA_URL = _BASE_URL + "/meta-data/"
_INSTANCE_TAGS_URL = _BASE_URL + "/meta-data/tags/instance"
_IAM_SECURITY_CREDENTIALS_URL = _BASE_URL + "/meta-data/iam/security-credentials/"
_TOKEN_TTL_SECONDS = "21600"  # nosec B105  session-token TTL (seconds), not a secret
_TIMEOUT_SECONDS = 5
_RETRY_MAX_ATTEMPTS = 3
_RETRY_WAIT_SECONDS = 1


def get_instance_id() -> str:
    """Return the id of the current instance, fetched from IMDSv2."""
    token = fetch_token()
    return _get(_INSTANCE_ID_URL, token)


def get_instance_type() -> str:
    """Return the EC2 instance type of the current instance (e.g. ``t3.xlarge``), from IMDSv2."""
    token = fetch_token()
    return _get(_INSTANCE_TYPE_URL, token)


def get_iam_role_name() -> Optional[str]:
    """Return the IAM role name exposed through the instance profile, or None if none is attached.

    IMDS lists the role(s) reachable via the instance profile under
    ``/meta-data/iam/security-credentials/``. When no instance profile is attached IMDS answers 404, so
    None is returned. A ParallelCluster node always has exactly one role; if IMDS ever lists more than
    one, the first is returned.
    """
    token = fetch_token()
    try:
        body = _get(_IAM_SECURITY_CREDENTIALS_URL, token)
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None
        raise
    names = [line.strip() for line in body.splitlines() if line.strip()]
    return names[0] if names else None


def list_metadata(imds_version: str) -> str:
    """Return the top-level IMDS metadata listing, using the enabled IMDS version."""
    return _get(_METADATA_URL, _token_for(imds_version))


def get_instance_tags(imds_version: str) -> str:
    """Return the IMDS instance tags listing; raises when the tags category is not exposed."""
    return _get(_INSTANCE_TAGS_URL, _token_for(imds_version))


def _token_for(imds_version: str) -> Optional[str]:
    """Return a session token for IMDSv2, or None for token-less IMDSv1."""
    return fetch_token() if imds_version == IMDS_V2 else None


@retry(stop_max_attempt_number=_RETRY_MAX_ATTEMPTS, wait_fixed=_RETRY_WAIT_SECONDS * 1000)
def fetch_token() -> str:
    """Fetch a short-lived IMDSv2 session token."""
    request = urllib.request.Request(
        _TOKEN_URL, method="PUT", headers={"X-aws-ec2-metadata-token-ttl-seconds": _TOKEN_TTL_SECONDS}
    )
    with urllib.request.urlopen(request, timeout=_TIMEOUT_SECONDS) as response:  # nosec B310  # nosemgrep
        return response.read().decode("utf-8")


def is_responsive_for_user(user: str) -> bool:
    """Return whether IMDS answers a token request issued as OS user ``user``.

    The probe runs as ``user`` (see ``run_command``'s ``as_user``, which drops privileges without a
    PAM session, so it never creates the user's home directory). The token (PUT) request works under
    both v1.0 and v2.0 and exercises the per-user iptables rules installed when
    ``HeadNode/Imds/Secured`` is enabled.

    A ``curl`` "could not connect" exit code means the lockdown REJECTed the request: a definitive
    denial, returned right away. Any other non-zero exit (e.g. a timeout) is treated as transient and
    retried before giving up.
    """
    command = [
        "curl",
        "--silent",
        "--fail",
        "--max-time",
        str(_TIMEOUT_SECONDS),
        "-X",
        "PUT",
        _TOKEN_URL,
        "-H",
        "X-aws-ec2-metadata-token-ttl-seconds: {}".format(_TOKEN_TTL_SECONDS),
    ]

    # Exit 0 (reachable) and 7 (curl could-not-connect: lockdown REJECTed the request) are definitive
    # answers and not retried; any other exit (e.g. a timeout) is transient.
    @retry(
        stop_max_attempt_number=_RETRY_MAX_ATTEMPTS,
        wait_fixed=_RETRY_WAIT_SECONDS * 1000,
        retry_on_result=lambda code: code not in (0, 7),
    )
    def probe() -> int:
        return run_command(command, timeout=_TIMEOUT_SECONDS + 10, as_user=user).returncode

    try:
        return probe() == 0
    except RetryError:
        return False  # Never got a definitive answer within the retry budget (transient timeouts).


@retry(stop_max_attempt_number=_RETRY_MAX_ATTEMPTS, wait_fixed=_RETRY_WAIT_SECONDS * 1000)
def _get(url: str, token: Optional[str] = None) -> str:
    """GET ``url`` from IMDS (with a session token for IMDSv2) and return the stripped body."""
    headers = {"X-aws-ec2-metadata-token": token} if token is not None else {}
    request = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(request, timeout=_TIMEOUT_SECONDS) as response:  # nosec B310  # nosemgrep
        return response.read().decode("utf-8").strip()
