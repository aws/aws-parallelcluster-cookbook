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


"""Unit tests for the AWS service endpoints a cluster depends on."""

import pytest

from pcluster_diag.util import aws_endpoints

_ALWAYS = ["ec2", "s3", "cloudformation", "dynamodb"]


@pytest.mark.parametrize(
    "cluster_config, expected",
    [
        # Defaults: CloudWatch logs are enabled when not configured.
        (None, _ALWAYS + ["logs"]),
        ({}, _ALWAYS + ["logs"]),
        # CloudWatch logs disabled.
        ({"Monitoring": {"Logs": {"CloudWatch": {"Enabled": False}}}}, _ALWAYS),
        # Directory service and login nodes add their endpoints.
        ({"DirectoryService": {"DomainName": "corp.example.com"}}, _ALWAYS + ["logs", "secretsmanager"]),
        ({"LoginNodes": {"Pools": [{"Name": "pool"}]}}, _ALWAYS + ["logs", "autoscaling", "elasticloadbalancing"]),
        # Explicit nulls, as in the cluster config with implied values.
        ({"DirectoryService": None, "LoginNodes": None, "Monitoring": None}, _ALWAYS + ["logs"]),
    ],
)
def test_required_services(cluster_config, expected):
    assert aws_endpoints.required_services(cluster_config) == expected


@pytest.mark.parametrize(
    "cluster_config, expected",
    [
        (
            None,
            [
                ("secretsmanager", "no DirectoryService is configured"),
                ("autoscaling", "no LoginNodes are configured"),
                ("elasticloadbalancing", "no LoginNodes are configured"),
            ],
        ),
        (
            {
                "Monitoring": {"Logs": {"CloudWatch": {"Enabled": False}}},
                "DirectoryService": {"DomainName": "corp.example.com"},
                "LoginNodes": {"Pools": [{"Name": "pool"}]},
            },
            [("logs", "CloudWatch Logs is disabled")],
        ),
    ],
)
def test_skipped_services(cluster_config, expected):
    assert aws_endpoints.skipped_services(cluster_config) == expected


def test_resolve_endpoints_resolves_each_service(monkeypatch):
    monkeypatch.setattr(aws_endpoints, "_endpoint_host", lambda service, region: f"{service}.{region}.amazonaws.com")

    endpoints = aws_endpoints.resolve_endpoints("us-east-1", ["ec2", "s3"])

    assert endpoints == [
        aws_endpoints.Endpoint("ec2", "ec2.us-east-1.amazonaws.com"),
        aws_endpoints.Endpoint("s3", "s3.us-east-1.amazonaws.com"),
    ]


def test_resolve_endpoints_skips_unresolvable_services(monkeypatch):
    monkeypatch.setattr(aws_endpoints, "_endpoint_host", lambda service, region: None if service == "s3" else "host")

    assert [endpoint.label for endpoint in aws_endpoints.resolve_endpoints("us-east-1", ["ec2", "s3"])] == ["ec2"]
