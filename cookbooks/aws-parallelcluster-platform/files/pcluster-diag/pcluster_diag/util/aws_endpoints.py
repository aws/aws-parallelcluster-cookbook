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

"""Resolve the AWS service endpoints ParallelCluster depends on, for the running region/partition.

The endpoint *hostnames* are resolved through botocore's own endpoint resolver (``boto3.client(...)
.meta.endpoint_url``) rather than hardcoded, so the correct domain of the partition (commercial, China,
GovCloud, ISO) is used automatically without this module knowing the partition rules. Creating a client
does not require credentials or make any network call -- only the resolved endpoint URL is read -- so this
is safe to call at diagnosis time.

Every endpoint ParallelCluster can interact with is probed (see :func:`services`). The ones the cluster
configuration needs are required; the others are optional, because the cluster may still use them through custom
actions, so their failures are reported with a lower severity rather than not at all.
"""

import logging
from dataclasses import dataclass
from typing import List, Optional, Tuple
from urllib.parse import urlparse

import boto3
from botocore.config import Config

logger = logging.getLogger(__name__)

# Resolve S3 in us-east-1 to its regional endpoint (s3.us-east-1) rather than to the global one (s3.amazonaws.com),
# which botocore uses by default there: an isolated environment exposes the regional endpoint, through a VPC endpoint
# or a proxy allowlist, so probing the global one would report a false failure. Other regions are not affected.
_RESOLVER_CONFIG = Config(s3={"us_east_1_regional_endpoint": "regional"})

# boto3 service names of the endpoints ParallelCluster interacts with: the ones every cluster needs, and the ones
# needed only when a feature is configured. Mirrors the VPC endpoints required for a subnet without internet access:
# https://docs.aws.amazon.com/parallelcluster/latest/ug/aws-parallelcluster-in-a-single-public-subnet-no-internet-v3.html
ALWAYS_REQUIRED_SERVICES = (
    "ec2",  # fleet management, RunInstances/CreateFleet, tags, health
    "s3",  # artifacts bucket, cluster config, cookbook, wait condition signal
    "cloudformation",  # cluster stack describe and cfn-hup updates
    "dynamodb",  # node-to-instance associations, compute fleet status
)
CLOUDWATCH_LOGS_SERVICES = ("logs",)  # when Monitoring/Logs/CloudWatch is enabled (default)
DIRECTORY_SERVICE_SERVICES = ("secretsmanager",)  # when DirectoryService is configured
LOGIN_NODES_SERVICES = ("autoscaling", "elbv2")  # when LoginNodes is configured (elbv2: the NLB API)


@dataclass(frozen=True)
class Service:
    """A service whose endpoint is probed: its boto3 ``name`` and, for an optional one, ``needed_when``.

    ``needed_when`` is None for a service the cluster configuration requires; otherwise it is the condition under
    which ParallelCluster uses the service (e.g. "a DirectoryService is configured").
    """

    name: str
    needed_when: Optional[str] = None


def services(cluster_config: Optional[dict]) -> List[Service]:
    """Return every service ParallelCluster can interact with, required or optional for ``cluster_config``."""
    result = [Service(name) for name in ALWAYS_REQUIRED_SERVICES]
    for feature_services, enabled, needed_when in _optional_features(cluster_config or {}):
        result.extend(Service(name, None if enabled else needed_when) for name in feature_services)
    return result


def _optional_features(config: dict) -> List[Tuple[Tuple[str, ...], bool, str]]:
    """Return ``(services, enabled, condition under which they are needed)`` for every optional feature."""
    cloudwatch_logs = ((config.get("Monitoring") or {}).get("Logs") or {}).get("CloudWatch") or {}
    return [
        (CLOUDWATCH_LOGS_SERVICES, cloudwatch_logs.get("Enabled", True) is not False, "CloudWatch Logs is enabled"),
        (DIRECTORY_SERVICE_SERVICES, bool(config.get("DirectoryService")), "a DirectoryService is configured"),
        (LOGIN_NODES_SERVICES, bool((config.get("LoginNodes") or {}).get("Pools")), "LoginNodes are configured"),
    ]


HTTPS_PORT = 443


@dataclass(frozen=True)
class Endpoint:
    """An endpoint to probe: a human ``label`` (the service name), its ``host`` and ``port``, and ``needed_when``.

    ``needed_when`` is None for an endpoint the cluster configuration requires, as in :class:`Service`.
    """

    label: str
    host: str
    port: int = HTTPS_PORT
    needed_when: Optional[str] = None

    @property
    def required(self) -> bool:
        """Return whether the cluster configuration requires this endpoint."""
        return self.needed_when is None


def resolve_endpoints(region: str, services_to_resolve: List[Service]) -> List[Endpoint]:
    """Return the resolvable AWS service endpoints for ``region``, one per service.

    Each service name is resolved to its regional endpoint host via botocore. A service that cannot be
    resolved in this region/partition (botocore raises, e.g. the service is not offered there) is
    logged and skipped rather than failing the whole enumeration -- an absent service is not a
    reachability failure.
    """
    endpoints: List[Endpoint] = []
    for service in services_to_resolve:
        host = _endpoint_host(service.name, region)
        if host:
            endpoints.append(Endpoint(label=service.name, host=host, needed_when=service.needed_when))
    return endpoints


def _endpoint_host(service: str, region: str):
    """Return the endpoint hostname for ``service`` in ``region``, or None if it cannot be resolved.

    Reads ``client.meta.endpoint_url`` (no network call, no credentials needed) and extracts the host.
    """
    try:
        endpoint_url = boto3.client(service, region_name=region, config=_RESOLVER_CONFIG).meta.endpoint_url
    except Exception as error:  # noqa: BLE001  botocore raises varied types for an unknown service/region
        logger.info("Could not resolve endpoint for service %r in %r: %s", service, region, error)
        return None
    host = urlparse(endpoint_url).hostname
    if not host:
        logger.info("Resolved endpoint URL %r for service %r has no host", endpoint_url, service)
        return None
    return host
