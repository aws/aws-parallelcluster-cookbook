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

"""Check that the AWS service endpoints ParallelCluster depends on are reachable over verified TLS.

For each endpoint the cluster needs, this probes the network path in the order the failures stack: DNS
resolution -> TCP connect on 443 -> a certificate-verified TLS handshake. Probing in that order means each
endpoint is reported at the *first* layer that fails (a DNS failure is not also reported as a TCP failure),
which points at the actual root cause -- a missing VPC endpoint / DNS, a blocked security group or route, or a
TLS-terminating proxy presenting an untrusted certificate.

When a proxy is configured, the endpoints are probed through it, as the ParallelCluster daemons reach them
(they pass the proxy to every boto3 client): TCP connect to the proxy, then for each endpoint an HTTP CONNECT
tunnel and the certificate-verified TLS handshake inside it. The proxy resolves the endpoint names, so there is
no local DNS step.
"""

import logging
from concurrent.futures import ThreadPoolExecutor
from functools import partial
from typing import List, Optional

from pcluster_diag.models.check import Check
from pcluster_diag.models.context import Context
from pcluster_diag.models.finding import CheckError, CheckFinding, CheckInfo
from pcluster_diag.models.result import INTERNAL_ERROR_CODE, Result
from pcluster_diag.util import aws_endpoints, network

logger = logging.getLogger(__name__)


class EndpointsAreReachable(Check):
    """Verify DNS, TCP:443, and certificate-verified TLS to each AWS endpoint ParallelCluster uses."""

    # --- Errors: per-endpoint, reported at the first failing layer ----------------------------
    DNS_FAILED = CheckError(1, "DNS resolution for the {} endpoint ({}) failed: {}")
    TCP_FAILED = CheckError(2, "TCP connection to the {} endpoint ({}:{}) failed: {}")
    TLS_CERT_INVALID = CheckError(
        3,
        "TLS certificate verification for the {} endpoint ({}) failed: {}. The endpoint is reachable "
        "but its certificate is not trusted.",
    )
    TLS_FAILED = CheckError(4, "TLS handshake to the {} endpoint ({}:{}) failed: {}")
    PROXY_UNREACHABLE = CheckError(5, "TCP connection to the proxy {} failed: {}. No endpoint was probed.")
    PROXY_TUNNEL_FAILED = CheckError(6, "The proxy {} did not open a tunnel to the {} endpoint ({}:{}): {}")

    # --- Errors: undeterminable (reserved E0 -> CHECK_ERROR, not FAILURE) ----------------------
    NO_ENDPOINTS = CheckError(
        INTERNAL_ERROR_CODE,
        "Could not determine the AWS endpoints to probe (no region in dna.json, or no endpoint resolved for it), "
        "so reachability was not evaluated.",
    )
    PROXY_INVALID = CheckError(
        INTERNAL_ERROR_CODE,
        "The proxy address in dna.json is not a valid HTTP(S) proxy address, so reachability was not evaluated.",
    )

    # --- Infos --------------------------------------------------------------------------------
    PROXY_CONFIGURED = CheckInfo(1, "A proxy is configured ({}): the endpoints are probed through it.")
    # Lists every probed endpoint with its outcome, and the endpoints not probed with the reason. When every
    # endpoint is reachable, the message starts with _ALL_REACHABLE.
    PROBE_SUMMARY = CheckInfo(2, "{}Probed: {}.{}")
    _ALL_REACHABLE = "All probed AWS endpoints are reachable over certificate-verified TLS. "

    # Outcome shown in the probe summary for each per-endpoint error code.
    _OUTCOMES = {
        DNS_FAILED.code: "DNS failed",
        TCP_FAILED.code: "TCP failed",
        TLS_CERT_INVALID.code: "certificate not trusted",
        TLS_FAILED.code: "TLS failed",
        PROXY_TUNNEL_FAILED.code: "proxy tunnel failed",
    }

    @property
    def description(self) -> str:
        """Return the human-readable description of this Check."""
        return "Verify that the AWS service endpoints ParallelCluster depends on are reachable over TLS."

    def run(self, context: Context) -> Result:
        """Probe every dependent endpoint, directly or through the proxy, and aggregate the findings."""
        region = self._region(context)
        services = aws_endpoints.required_services(context.cluster_config)
        endpoints = aws_endpoints.resolve_endpoints(region, services) if region else []
        if not endpoints:
            # Reported as a CHECK_ERROR (reserved E0), distinct from a reachability FAILURE.
            return Result.from_findings(self, errors=[self.NO_ENDPOINTS])

        infos: List[CheckFinding] = []
        proxy_address = self._proxy(context)
        proxy = network.parse_proxy(proxy_address) if proxy_address else None
        if proxy_address and not proxy:
            return Result.from_findings(self, errors=[self.PROXY_INVALID])
        if proxy:
            infos.append(self.PROXY_CONFIGURED.format(proxy))
            # Every endpoint is probed through the proxy: when it is unreachable, report it once.
            proxy_tcp = network.tcp_connect(proxy.host, proxy.port)
            if not proxy_tcp.connected:
                return Result.from_findings(
                    self, errors=[self.PROXY_UNREACHABLE.format(proxy, proxy_tcp.error)], infos=infos
                )

        # Probe the endpoints concurrently: on a node without a route to some endpoints every probe waits for
        # its timeout, so probing them one after another would add up the timeouts.
        probe = partial(self._probe_endpoint_via_proxy, proxy=proxy) if proxy else self._probe_endpoint
        with ThreadPoolExecutor(max_workers=len(endpoints)) as executor:
            findings = list(executor.map(probe, endpoints))
        errors: List[CheckFinding] = [finding for finding in findings if finding]

        infos.append(
            self.PROBE_SUMMARY.format(
                "" if errors else self._ALL_REACHABLE,
                ", ".join(
                    "{} ({}): {}".format(
                        endpoint.label, endpoint.host, self._OUTCOMES[finding.code] if finding else "reachable"
                    )
                    for endpoint, finding in zip(endpoints, findings)
                ),
                self._not_probed(context, region, services, endpoints),
            )
        )
        return Result.from_findings(self, errors=errors or None, infos=infos)

    @staticmethod
    def _not_probed(context: Context, region: str, services: List[str], endpoints: List[aws_endpoints.Endpoint]) -> str:
        """Return a sentence listing the services that were not probed and why, or "" when none was skipped.

        A service is not probed when the cluster does not use the feature that needs it, or when botocore
        resolves no endpoint for it in the region.
        """
        resolved = {endpoint.label for endpoint in endpoints}
        skipped = [(service, "no endpoint in {}".format(region)) for service in services if service not in resolved]
        skipped += aws_endpoints.skipped_services(context.cluster_config)
        if not skipped:
            return ""
        return " Not probed: {}.".format(", ".join("{} ({})".format(service, reason) for service, reason in skipped))

    def _probe_endpoint(self, endpoint: aws_endpoints.Endpoint) -> Optional[CheckFinding]:
        """Return the first-layer failure for ``endpoint`` (DNS, then TCP, then TLS), or None if reachable.

        Short-circuits at the first failing layer so the finding names the real root cause rather than a
        downstream symptom (a DNS failure would otherwise also surface as a TCP failure).
        """
        dns = network.resolve_host_isolated(endpoint.host)
        if not dns.resolved:
            return self.DNS_FAILED.format(endpoint.label, endpoint.host, dns.error)

        tcp = network.tcp_connect(endpoint.host, endpoint.port)
        if not tcp.connected:
            return self.TCP_FAILED.format(endpoint.label, endpoint.host, endpoint.port, tcp.error)

        tls = network.tls_handshake(endpoint.host, endpoint.port)
        if not tls.connected:
            if tls.verification_failed:
                return self.TLS_CERT_INVALID.format(endpoint.label, endpoint.host, tls.error)
            return self.TLS_FAILED.format(endpoint.label, endpoint.host, endpoint.port, tls.error)

        return None

    def _probe_endpoint_via_proxy(
        self, endpoint: aws_endpoints.Endpoint, proxy: network.Proxy
    ) -> Optional[CheckFinding]:
        """Return the failure for ``endpoint`` probed through ``proxy`` (tunnel, then TLS), or None if reachable."""
        tls = network.tls_handshake_via_proxy(endpoint.host, endpoint.port, proxy)
        if tls.connected:
            return None
        if tls.tunnel_failed:
            return self.PROXY_TUNNEL_FAILED.format(proxy, endpoint.label, endpoint.host, endpoint.port, tls.error)
        if tls.verification_failed:
            return self.TLS_CERT_INVALID.format(endpoint.label, endpoint.host, tls.error)
        return self.TLS_FAILED.format(endpoint.label, endpoint.host, endpoint.port, tls.error)

    @staticmethod
    def _region(context: Context) -> Optional[str]:
        """Return the AWS region from ``dna.json`` (``cluster.region``), which ParallelCluster always sets."""
        return (((context.dna_json or {}).get("cluster")) or {}).get("region")

    @staticmethod
    def _proxy(context: Context) -> Optional[str]:
        """Return the configured HTTP proxy address from ``dna.json`` (``cluster.proxy``), or None.

        ParallelCluster records the head node or queue proxy (``HttpProxyAddress``) under ``cluster.proxy``.
        """
        proxy = (((context.dna_json or {}).get("cluster")) or {}).get("proxy")
        # dna.json uses the literal string "NONE" when no proxy is configured.
        if proxy and proxy != "NONE":
            return proxy
        return None
