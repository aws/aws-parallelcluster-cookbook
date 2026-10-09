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

"""Unit tests for the endpoint-reachability check (DNS -> TCP:443 -> verified TLS per AWS endpoint)."""

import threading

import pytest

from pcluster_diag.checks import endpoint_reachability as check_module
from pcluster_diag.checks.endpoint_reachability import EndpointsAreReachable
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.util.aws_endpoints import Endpoint
from pcluster_diag.util.network import DnsResult, TcpResult, TlsResult
from tests.sample_data import sample_context

_TWO_ENDPOINTS = [Endpoint("ec2", "ec2.us-east-1.amazonaws.com"), Endpoint("s3", "s3.us-east-1.amazonaws.com")]


def _context():
    """Return a sample Context whose dna.json carries the region, as on every cluster node."""
    context = sample_context()
    context.dna_json = dict(context.dna_json, cluster=dict(context.dna_json["cluster"], region="us-east-1"))
    return context


def _codes(findings):
    """Return the set of finding codes (e.g. {'E1', 'I2'}) from a findings list (None-safe)."""
    return {finding.code for finding in (findings or [])}


@pytest.fixture
def all_reachable(monkeypatch):
    """Patch the endpoint list and network probes so every endpoint is fully reachable by default."""
    monkeypatch.setattr(check_module.aws_endpoints, "resolve_endpoints", lambda region, services: list(_TWO_ENDPOINTS))
    monkeypatch.setattr(
        check_module.network, "resolve_host_isolated", lambda host, **kw: DnsResult(resolved=True, error=None)
    )
    monkeypatch.setattr(
        check_module.network, "tcp_connect", lambda host, port, **kw: TcpResult(connected=True, error=None)
    )
    monkeypatch.setattr(
        check_module.network,
        "tls_handshake",
        lambda host, port=443, **kw: TlsResult(connected=True, error=None),
    )
    monkeypatch.setattr(
        check_module.network,
        "tls_handshake_via_proxy",
        lambda host, port, proxy, **kw: TlsResult(connected=True, error=None),
    )


def test_description():
    assert "AWS service endpoints" in EndpointsAreReachable().description


def test_should_run_on_every_node_type():
    for node_type in NodeType:
        assert EndpointsAreReachable().should_run(sample_context(node_type)) is True


def test_all_endpoints_reachable_passes(all_reachable):
    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.PASSED
    assert result.errors is None
    # I2 = PROBE_SUMMARY.
    assert "I2" in _codes(result.infos)


def test_probe_summary_lists_probed_and_skipped_endpoints(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.aws_endpoints, "required_services", lambda cluster_config: ["ec2", "s3", "cloudformation"]
    )
    monkeypatch.setattr(
        check_module.aws_endpoints,
        "skipped_services",
        lambda cluster_config: [("secretsmanager", "no DirectoryService is configured")],
    )

    result = EndpointsAreReachable().run(_context())

    (summary,) = [info for info in result.infos if info.code == "I2"]
    assert summary.message == (
        "All probed AWS endpoints are reachable over certificate-verified TLS. "
        "Probed: ec2 (ec2.us-east-1.amazonaws.com): reachable, s3 (s3.us-east-1.amazonaws.com): reachable. "
        "Not probed: cloudformation (no endpoint in us-east-1), secretsmanager (no DirectoryService is configured)."
    )


def test_probe_summary_omits_not_probed_when_nothing_is_skipped(all_reachable, monkeypatch):
    monkeypatch.setattr(check_module.aws_endpoints, "required_services", lambda cluster_config: ["ec2", "s3"])
    monkeypatch.setattr(check_module.aws_endpoints, "skipped_services", lambda cluster_config: [])

    result = EndpointsAreReachable().run(_context())

    (summary,) = [info for info in result.infos if info.code == "I2"]
    assert summary.message == (
        "All probed AWS endpoints are reachable over certificate-verified TLS. "
        "Probed: ec2 (ec2.us-east-1.amazonaws.com): reachable, s3 (s3.us-east-1.amazonaws.com): reachable."
    )


@pytest.mark.parametrize(
    "failing_layer, outcome",
    [
        ("dns", "DNS failed"),
        ("tcp", "TCP failed"),
        ("certificate", "certificate not trusted"),
        ("tls", "TLS failed"),
    ],
)
def test_probe_summary_lists_failed_endpoints_with_their_outcome(all_reachable, monkeypatch, failing_layer, outcome):
    s3_host = "s3.us-east-1.amazonaws.com"
    monkeypatch.setattr(check_module.aws_endpoints, "required_services", lambda cluster_config: ["ec2", "s3"])
    monkeypatch.setattr(check_module.aws_endpoints, "skipped_services", lambda cluster_config: [])
    if failing_layer == "dns":
        monkeypatch.setattr(
            check_module.network,
            "resolve_host_isolated",
            lambda host, **kw: DnsResult(resolved=host != s3_host, error="x"),
        )
    elif failing_layer == "tcp":
        monkeypatch.setattr(
            check_module.network,
            "tcp_connect",
            lambda host, port, **kw: TcpResult(connected=host != s3_host, error="x"),
        )
    else:
        monkeypatch.setattr(
            check_module.network,
            "tls_handshake",
            lambda host, port=443, **kw: TlsResult(
                connected=host != s3_host, error="x", verification_failed=failing_layer == "certificate"
            ),
        )

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.FAILURE
    (summary,) = [info for info in result.infos if info.code == "I2"]
    assert summary.message == (
        "Probed: ec2 (ec2.us-east-1.amazonaws.com): reachable, s3 (s3.us-east-1.amazonaws.com): {}.".format(outcome)
    )


def test_dns_failure_reported_as_failure(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network,
        "resolve_host_isolated",
        lambda host, **kw: DnsResult(resolved=host != "ec2.us-east-1.amazonaws.com", error="NXDOMAIN"),
    )

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.FAILURE
    assert _codes(result.errors) == {"E1"}  # only the ec2 endpoint failed, at the DNS layer


def test_tcp_failure_reported_as_failure(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network,
        "tcp_connect",
        lambda host, port, **kw: TcpResult(connected=host != "s3.us-east-1.amazonaws.com", error="timed out"),
    )

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.FAILURE
    assert _codes(result.errors) == {"E2"}


def test_certificate_verification_failure_reported_distinctly(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network,
        "tls_handshake",
        lambda host, port=443, **kw: TlsResult(connected=False, error="self-signed", verification_failed=True),
    )

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.FAILURE
    # E3 = TLS_CERT_INVALID for both endpoints (distinct from a transport TLS failure).
    assert _codes(result.errors) == {"E3"}


def test_tls_transport_failure_reported_as_failure(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network,
        "tls_handshake",
        lambda host, port=443, **kw: TlsResult(connected=False, error="reset", verification_failed=False),
    )

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.FAILURE
    assert _codes(result.errors) == {"E4"}


def test_first_failing_layer_short_circuits(all_reachable, monkeypatch):
    # A DNS failure must not also be reported as a TCP/TLS failure for the same endpoint.
    monkeypatch.setattr(
        check_module.network, "resolve_host_isolated", lambda host, **kw: DnsResult(resolved=False, error="NXDOMAIN")
    )
    monkeypatch.setattr(check_module.network, "tcp_connect", lambda host, port, **kw: pytest.fail("TCP should not run"))

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.FAILURE
    assert _codes(result.errors) == {"E1"}


def test_region_missing_from_dna_json_is_check_error(monkeypatch):
    monkeypatch.setattr(
        check_module.aws_endpoints, "resolve_endpoints", lambda region, services: pytest.fail("nothing to resolve")
    )
    context = _context()
    context.dna_json = {"cluster": {}}

    result = EndpointsAreReachable().run(context)

    assert result.status == Status.CHECK_ERROR  # E0 NO_ENDPOINTS, not a reachability FAILURE
    assert _codes(result.errors) == {"E0"}


def test_no_resolvable_endpoints_is_check_error(monkeypatch):
    monkeypatch.setattr(check_module.aws_endpoints, "resolve_endpoints", lambda region, services: [])

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.CHECK_ERROR
    assert _codes(result.errors) == {"E0"}


def _proxy_context(proxy="http://user:secret@proxy.local:3128"):
    context = _context()
    context.dna_json = {"cluster": {"region": "us-east-1", "proxy": proxy}}
    return context


def test_configured_proxy_is_surfaced_as_info(all_reachable):
    result = EndpointsAreReachable().run(_proxy_context())

    assert result.status == Status.PASSED
    # I1 = PROXY_CONFIGURED, I2 = PROBE_SUMMARY.
    assert {"I1", "I2"} <= _codes(result.infos)
    (proxy_info,) = [info for info in result.infos if info.code == "I1"]
    # The credentials in the proxy address are not shown.
    assert proxy_info.message == "A proxy is configured (http://proxy.local:3128): the endpoints are probed through it."


def test_endpoints_are_probed_through_the_proxy(all_reachable, monkeypatch):
    probed = []

    def _via_proxy(host, port, proxy, **kw):
        probed.append((host, port, proxy.host, proxy.port))
        return TlsResult(connected=True, error=None)

    monkeypatch.setattr(check_module.network, "tls_handshake_via_proxy", _via_proxy)
    # The proxy resolves the endpoint names and connects to them: no direct probe is made.
    monkeypatch.setattr(check_module.network, "resolve_host_isolated", lambda host, **kw: pytest.fail("no local DNS"))
    monkeypatch.setattr(
        check_module.network, "tls_handshake", lambda host, port=443, **kw: pytest.fail("no direct TLS")
    )

    result = EndpointsAreReachable().run(_proxy_context())

    assert result.status == Status.PASSED
    assert sorted(probed) == [
        ("ec2.us-east-1.amazonaws.com", 443, "proxy.local", 3128),
        ("s3.us-east-1.amazonaws.com", 443, "proxy.local", 3128),
    ]


def test_unreachable_proxy_is_reported_once(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network,
        "tcp_connect",
        lambda host, port, **kw: TcpResult(connected=host != "proxy.local", error="timed out"),
    )
    monkeypatch.setattr(
        check_module.network, "tls_handshake_via_proxy", lambda *args, **kw: pytest.fail("no endpoint probe")
    )

    result = EndpointsAreReachable().run(_proxy_context())

    assert result.status == Status.FAILURE
    (error,) = result.errors
    assert error.code == "E5"
    assert error.message == (
        "TCP connection to the proxy http://proxy.local:3128 failed: timed out. No endpoint was probed."
    )
    assert _codes(result.infos) == {"I1"}


@pytest.mark.parametrize(
    "tls, code, outcome",
    [
        (
            TlsResult(connected=False, error="the proxy answered 'HTTP/1.1 403 Forbidden'", tunnel_failed=True),
            "E6",
            "proxy tunnel failed",
        ),
        (TlsResult(connected=False, error="self-signed", verification_failed=True), "E3", "certificate not trusted"),
        (TlsResult(connected=False, error="reset"), "E4", "TLS failed"),
    ],
)
def test_proxied_endpoint_failures(all_reachable, monkeypatch, tls, code, outcome):
    s3_host = "s3.us-east-1.amazonaws.com"
    monkeypatch.setattr(
        check_module.network,
        "tls_handshake_via_proxy",
        lambda host, port, proxy, **kw: tls if host == s3_host else TlsResult(connected=True, error=None),
    )

    result = EndpointsAreReachable().run(_proxy_context())

    assert result.status == Status.FAILURE
    assert _codes(result.errors) == {code}
    (summary,) = [info for info in result.infos if info.code == "I2"]
    assert "s3 ({}): {}".format(s3_host, outcome) in summary.message
    assert "ec2 (ec2.us-east-1.amazonaws.com): reachable" in summary.message


def test_proxy_tunnel_failure_names_the_proxy_and_the_endpoint(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network,
        "tls_handshake_via_proxy",
        lambda host, port, proxy, **kw: TlsResult(
            connected=False, error="the proxy answered 'HTTP/1.1 403 Forbidden'", tunnel_failed=True
        ),
    )

    result = EndpointsAreReachable().run(_proxy_context())

    assert result.errors[0].message == (
        "The proxy http://proxy.local:3128 did not open a tunnel to the ec2 endpoint "
        "(ec2.us-east-1.amazonaws.com:443): the proxy answered 'HTTP/1.1 403 Forbidden'"
    )


def test_invalid_proxy_address_is_check_error(all_reachable):
    result = EndpointsAreReachable().run(_proxy_context("ftp://proxy.local:21"))

    assert result.status == Status.CHECK_ERROR
    assert _codes(result.errors) == {"E0"}


def test_proxy_none_sentinel_is_not_treated_as_proxy(all_reachable):
    context = _context()
    context.dna_json = {"cluster": {"region": "us-east-1", "proxy": "NONE"}}

    result = EndpointsAreReachable().run(context)

    assert "I1" not in _codes(result.infos)


def test_probes_only_the_services_the_cluster_requires(all_reachable, monkeypatch):
    requested = []

    def _resolve(region, services):
        requested.append(list(services))
        return list(_TWO_ENDPOINTS)

    monkeypatch.setattr(check_module.aws_endpoints, "resolve_endpoints", _resolve)
    context = _context()
    context.cluster_config = dict(context.cluster_config, Monitoring={"Logs": {"CloudWatch": {"Enabled": False}}})

    EndpointsAreReachable().run(context)

    assert requested == [check_module.aws_endpoints.required_services(context.cluster_config)]
    assert "logs" not in requested[0]


def test_endpoints_are_probed_concurrently(all_reachable, monkeypatch):
    # Every probe blocks until all of them have started: this only completes if they run in parallel.
    barrier = threading.Barrier(len(_TWO_ENDPOINTS), timeout=5)

    def _tcp_connect(host, port, **kw):
        barrier.wait()
        return TcpResult(connected=True, error=None)

    monkeypatch.setattr(check_module.network, "tcp_connect", _tcp_connect)

    result = EndpointsAreReachable().run(_context())

    assert result.status == Status.PASSED


def test_findings_keep_the_endpoint_order(all_reachable, monkeypatch):
    monkeypatch.setattr(
        check_module.network, "resolve_host_isolated", lambda host, **kw: DnsResult(resolved=False, error="NXDOMAIN")
    )

    result = EndpointsAreReachable().run(_context())

    assert ["ec2" in result.errors[0].message, "s3" in result.errors[1].message] == [True, True]
