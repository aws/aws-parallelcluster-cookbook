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

import boto3
import pytest

from pcluster_diag.util import aws_endpoints

Service = aws_endpoints.Service

_ALWAYS = [Service("ec2"), Service("s3"), Service("cloudformation"), Service("dynamodb")]
_LOGS_NEEDED_WHEN = "CloudWatch Logs is enabled"
_DS_NEEDED_WHEN = "a DirectoryService is configured"
_LOGIN_NODES_NEEDED_WHEN = "LoginNodes are configured"


@pytest.mark.parametrize(
    "cluster_config, expected",
    [
        # Defaults: CloudWatch logs are enabled when not configured.
        (
            None,
            _ALWAYS
            + [
                Service("logs"),
                Service("secretsmanager", _DS_NEEDED_WHEN),
                Service("autoscaling", _LOGIN_NODES_NEEDED_WHEN),
                Service("elbv2", _LOGIN_NODES_NEEDED_WHEN),
            ],
        ),
        # Explicit nulls, as in the cluster config with implied values, behave like the defaults.
        (
            {"DirectoryService": None, "LoginNodes": None, "Monitoring": None},
            _ALWAYS
            + [
                Service("logs"),
                Service("secretsmanager", _DS_NEEDED_WHEN),
                Service("autoscaling", _LOGIN_NODES_NEEDED_WHEN),
                Service("elbv2", _LOGIN_NODES_NEEDED_WHEN),
            ],
        ),
        # Every optional feature flipped: the required services become optional and vice versa.
        (
            {
                "Monitoring": {"Logs": {"CloudWatch": {"Enabled": False}}},
                "DirectoryService": {"DomainName": "corp.example.com"},
                "LoginNodes": {"Pools": [{"Name": "pool"}]},
            },
            _ALWAYS
            + [
                Service("logs", _LOGS_NEEDED_WHEN),
                Service("secretsmanager"),
                Service("autoscaling"),
                Service("elbv2"),
            ],
        ),
    ],
)
def test_services_include_every_service_required_or_optional(cluster_config, expected):
    assert aws_endpoints.services(cluster_config) == expected


def test_resolve_endpoints_resolves_each_service(monkeypatch):
    monkeypatch.setattr(aws_endpoints, "_endpoint_host", lambda service, region: f"{service}.{region}.amazonaws.com")

    endpoints = aws_endpoints.resolve_endpoints("us-east-1", [Service("ec2"), Service("s3", _DS_NEEDED_WHEN)])

    assert endpoints == [
        aws_endpoints.Endpoint("ec2", "ec2.us-east-1.amazonaws.com"),
        aws_endpoints.Endpoint("s3", "s3.us-east-1.amazonaws.com", needed_when=_DS_NEEDED_WHEN),
    ]
    assert [endpoint.required for endpoint in endpoints] == [True, False]


def test_resolve_endpoints_skips_unresolvable_services(monkeypatch):
    monkeypatch.setattr(aws_endpoints, "_endpoint_host", lambda service, region: None if service == "s3" else "host")

    endpoints = aws_endpoints.resolve_endpoints("us-east-1", [Service("ec2"), Service("s3")])

    assert [endpoint.label for endpoint in endpoints] == ["ec2"]


def test_every_service_is_a_valid_boto3_service():
    # A misspelled service name never resolves to an endpoint, so it would silently never be probed.
    every_service = {service.name for service in aws_endpoints.services(None)}
    assert every_service <= set(boto3.session.Session().get_available_services())
