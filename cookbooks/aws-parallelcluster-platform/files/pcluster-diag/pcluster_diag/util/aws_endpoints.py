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
.meta.endpoint_url``) rather than hardcoded, so the correct partition domain is used automatically
(``amazonaws.com``, ``amazonaws.com.cn``, ``c2s.ic.gov``, ...) without this module knowing the
partition rules. Creating a client does not require credentials or make any network call -- only the
resolved endpoint URL is read -- so this is safe to call at diagnosis time.

The service list is derived from the cluster configuration: the endpoints every cluster needs plus those of
the optional features it configures (see :func:`required_services`). An endpoint a cluster never uses being
unreachable is not a ParallelCluster problem, so it is not probed.
"""

import logging
from dataclasses import dataclass
from typing import List, Optional, Tuple
from urllib.parse import urlparse

import boto3

logger = logging.getLogger(__name__)

# boto3 service names of the endpoints every ParallelCluster cluster depends on, and of the endpoints needed
# only when a feature is configured. Mirrors the VPC endpoints required for a subnet without internet access:
# https://docs.aws.amazon.com/parallelcluster/latest/ug/aws-parallelcluster-in-a-single-public-subnet-no-internet-v3.html
ALWAYS_REQUIRED_SERVICES = (
    "ec2",  # fleet management, RunInstances/CreateFleet, tags, health
    "s3",  # artifacts bucket, cluster config, cookbook, wait condition signal
    "cloudformation",  # cluster stack describe and cfn-hup updates
    "dynamodb",  # node-to-instance associations, compute fleet status
)
CLOUDWATCH_LOGS_SERVICES = ("logs",)  # when Monitoring/Logs/CloudWatch is enabled (default)
DIRECTORY_SERVICE_SERVICES = ("secretsmanager",)  # when DirectoryService is configured
LOGIN_NODES_SERVICES = ("autoscaling", "elasticloadbalancing")  # when LoginNodes is configured


def required_services(cluster_config: Optional[dict]) -> List[str]:
    """Return the boto3 service names of the endpoints the cluster described by ``cluster_config`` needs.

    Optional features are probed only when configured, so an endpoint the cluster never uses (e.g. a VPC
    without a Secrets Manager endpoint on a cluster without a directory service) is not reported as unreachable.
    """
    services = list(ALWAYS_REQUIRED_SERVICES)
    for feature_services, enabled, _ in _optional_features(cluster_config or {}):
        if enabled:
            services.extend(feature_services)
    return services


def skipped_services(cluster_config: Optional[dict]) -> List[Tuple[str, str]]:
    """Return ``(service, reason)`` for every optional endpoint the cluster does not need, in probe order."""
    return [
        (service, reason)
        for feature_services, enabled, reason in _optional_features(cluster_config or {})
        if not enabled
        for service in feature_services
    ]


def _optional_features(config: dict) -> List[Tuple[Tuple[str, ...], bool, str]]:
    """Return ``(services, enabled, reason they are skipped when disabled)`` for every optional feature."""
    cloudwatch_logs = ((config.get("Monitoring") or {}).get("Logs") or {}).get("CloudWatch") or {}
    return [
        (CLOUDWATCH_LOGS_SERVICES, cloudwatch_logs.get("Enabled", True) is not False, "CloudWatch Logs is disabled"),
        (DIRECTORY_SERVICE_SERVICES, bool(config.get("DirectoryService")), "no DirectoryService is configured"),
        (LOGIN_NODES_SERVICES, bool((config.get("LoginNodes") or {}).get("Pools")), "no LoginNodes are configured"),
    ]


HTTPS_PORT = 443


@dataclass(frozen=True)
class Endpoint:
    """An endpoint to probe: a human ``label`` (the service name), its ``host``, and ``port``."""

    label: str
    host: str
    port: int = HTTPS_PORT


def resolve_endpoints(region: str, services) -> List[Endpoint]:
    """Return the resolvable AWS service endpoints for ``region``, one per service.

    Each service name is resolved to its regional endpoint host via botocore. A service that cannot be
    resolved in this region/partition (botocore raises, e.g. the service is not offered there) is
    logged and skipped rather than failing the whole enumeration -- an absent service is not a
    reachability failure.
    """
    endpoints: List[Endpoint] = []
    for service in services:
        host = _endpoint_host(service, region)
        if host:
            endpoints.append(Endpoint(label=service, host=host))
    return endpoints


def _endpoint_host(service: str, region: str):
    """Return the endpoint hostname for ``service`` in ``region``, or None if it cannot be resolved.

    Reads ``client.meta.endpoint_url`` (no network call, no credentials needed) and extracts the host.
    """
    try:
        endpoint_url = boto3.client(service, region_name=region).meta.endpoint_url
    except Exception as error:  # noqa: BLE001  botocore raises varied types for an unknown service/region
        logger.info("Could not resolve endpoint for service %r in %r: %s", service, region, error)
        return None
    host = urlparse(endpoint_url).hostname
    if not host:
        logger.info("Resolved endpoint URL %r for service %r has no host", endpoint_url, service)
        return None
    return host
