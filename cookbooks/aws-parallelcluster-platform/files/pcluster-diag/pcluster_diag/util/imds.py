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

"""Helpers for querying the EC2 Instance Metadata Service (IMDSv2)."""

import urllib.request

_BASE_URL = "http://169.254.169.254/latest"  # nosec B104  link-local IMDS endpoint
_TOKEN_URL = _BASE_URL + "/api/token"
_INSTANCE_ID_URL = _BASE_URL + "/meta-data/instance-id"
_TOKEN_TTL_SECONDS = "21600"  # nosec B105  session-token TTL (seconds), not a secret
_TIMEOUT_SECONDS = 5


def get_instance_id() -> str:
    """Return the id of the current instance, fetched from IMDSv2."""
    token = _fetch_token()
    return _get(_INSTANCE_ID_URL, token)


def _fetch_token() -> str:
    """Fetch a short-lived IMDSv2 session token."""
    request = urllib.request.Request(
        _TOKEN_URL, method="PUT", headers={"X-aws-ec2-metadata-token-ttl-seconds": _TOKEN_TTL_SECONDS}
    )
    with urllib.request.urlopen(request, timeout=_TIMEOUT_SECONDS) as response:  # nosec B310  # nosemgrep
        return response.read().decode("utf-8")


def _get(url: str, token: str) -> str:
    """GET ``url`` from IMDS with the given session token and return the stripped body."""
    request = urllib.request.Request(url, headers={"X-aws-ec2-metadata-token": token})
    with urllib.request.urlopen(request, timeout=_TIMEOUT_SECONDS) as response:  # nosec B310  # nosemgrep
        return response.read().decode("utf-8").strip()
