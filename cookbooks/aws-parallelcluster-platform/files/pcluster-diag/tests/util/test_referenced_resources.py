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

"""Unit tests for reading the AWS resources the cluster configuration references."""

import http.client
import io
import json

import pytest
from botocore.exceptions import ClientError, EndpointConnectionError

from pcluster_diag.util import referenced_resources
from pcluster_diag.util.referenced_resources import ReadFailure, ResourceReader
from tests.stubs import stub_raising, stub_returning

_ROLE_ARN = "arn:aws:iam::123456789012:role/parallelcluster/my-head-role"
_PROFILE_ARN = "arn:aws:iam::123456789012:instance-profile/my-compute-profile"
_POLICY_ARN = "arn:aws:iam::123456789012:policy/my-policy"
_AWS_POLICY_ARN = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"

_CONFIG = {
    "HeadNode": {
        "Networking": {"SubnetId": "subnet-1", "SecurityGroups": ["sg-head"]},
        "Iam": {"InstanceRole": _ROLE_ARN},
        "CustomActions": {
            "OnNodeStart": {"Script": "s3://my-bucket/start.sh", "Args": ["a"]},
            "OnNodeConfigured": {
                "Sequence": [{"Script": "https://example.com/configured.sh"}, {"Script": "s3://my-bucket/start.sh"}]
            },
        },
    },
    "Scheduling": {
        "SlurmQueues": [
            {
                "Name": "q1",
                "Networking": {"SecurityGroups": None, "AdditionalSecurityGroups": ["sg-queue", "sg-head"]},
                "Iam": {
                    "InstanceProfile": _PROFILE_ARN,
                    "AdditionalIamPolicies": [{"Policy": _POLICY_ARN}, {"Policy": _AWS_POLICY_ARN}],
                },
            }
        ]
    },
    "SharedStorage": [
        {"Name": "efs", "StorageType": "Efs", "MountDir": "/efs", "EfsSettings": {"FileSystemId": "fs-efs"}},
        {"Name": "ebs", "StorageType": "Ebs", "MountDir": "/ebs", "EbsSettings": {"Size": 40}},
        {
            "Name": "fsx",
            "StorageType": "FsxLustre",
            "MountDir": "/fsx",
            "FsxLustreSettings": {"FileSystemId": "fs-fsx"},
        },
        {"Name": "ontap", "StorageType": "FsxOntap", "MountDir": "/ontap", "FsxOntapSettings": {"VolumeId": "fsvol-1"}},
        {"Name": "unknown", "StorageType": "Unknown", "MountDir": "/x"},
    ],
}


def _access_denied(operation):
    return ClientError({"Error": {"Code": "AccessDenied", "Message": "not authorized"}}, operation)


class _FakeClient:
    """A boto3 client whose operations return, or raise, the canned value of their name; a callable is called."""

    def __init__(self, responses):
        self.calls = []
        self._responses = responses

    def __getattr__(self, operation):
        def _operation(**kwargs):
            self.calls.append((operation, kwargs))
            response = self._responses[operation]
            if callable(response):
                response = response(**kwargs)
            if isinstance(response, Exception):
                raise response
            return dict(response, ResponseMetadata={"HTTPStatusCode": 200})

        return _operation


def _stack_resource(StackName, LogicalResourceId):  # noqa: N803 - boto3 parameter names
    if LogicalResourceId == "ComputeSecurityGroup":
        return {"StackResourceDetail": {"PhysicalResourceId": "sg-compute"}}
    return ClientError({"Error": {"Code": "ValidationError", "Message": "does not exist"}}, "DescribeStackResource")


def _route_tables(Filters):  # noqa: N803 - boto3 parameter names
    """Return the route table explicitly associated with subnet-1; the other subnets use the main route table."""
    filters = {item["Name"]: item["Values"] for item in Filters}
    if filters.get("association.subnet-id") == ["subnet-1"]:
        return {"RouteTables": [{"RouteTableId": "rtb-subnet-1", "Associations": [{"SubnetId": "subnet-1"}]}]}
    if filters.get("association.main") == ["true"]:
        return {"RouteTables": [{"RouteTableId": "rtb-main"}]}
    return {"RouteTables": []}


def _clients(**overrides):
    clients = {
        "ec2": _FakeClient(
            {
                "describe_instances": {
                    "Reservations": [
                        {"Instances": [{"SecurityGroups": [{"GroupId": "sg-node"}], "SubnetId": "subnet-node"}]}
                    ]
                },
                "describe_subnets": lambda SubnetIds: {  # noqa: N803
                    "Subnets": [{"SubnetId": SubnetIds[0], "VpcId": "vpc-1", "CidrBlock": "10.0.0.0/24"}]
                },
                "describe_route_tables": _route_tables,
                "describe_network_acls": {
                    "NetworkAcls": [{"NetworkAclId": "acl-1", "Associations": [{"SubnetId": "subnet-1"}]}]
                },
                "describe_vpc_endpoints": {"VpcEndpoints": [{"ServiceName": "com.amazonaws.us-east-1.s3"}]},
                "describe_security_groups": lambda GroupIds: {  # noqa: N803
                    "SecurityGroups": [{"GroupId": GroupIds[0], "IpPermissions": [{"IpProtocol": "-1"}]}]
                },
            }
        ),
        "cloudformation": _FakeClient({"describe_stack_resource": _stack_resource}),
        "iam": _FakeClient(
            {
                "get_instance_profile": lambda InstanceProfileName: {  # noqa: N803
                    "InstanceProfile": {
                        "Arn": "arn:aws:iam::123456789012:instance-profile/" + InstanceProfileName,
                        "Roles": [{"RoleName": InstanceProfileName.replace("profile", "role")}],
                    }
                },
                "get_role": lambda RoleName: {
                    "Role": {"RoleName": RoleName, "AssumeRolePolicyDocument": {}}
                },  # noqa: N803
                "list_attached_role_policies": {"AttachedPolicies": [{"PolicyArn": _POLICY_ARN}]},
                "list_role_policies": {"PolicyNames": ["inline"]},
                "get_role_policy": {"PolicyDocument": {"Statement": []}},
                "get_policy": {"Policy": {"DefaultVersionId": "v2"}},
                "get_policy_version": {"PolicyVersion": {"Document": {"Statement": [{"Effect": "Allow"}]}}},
            }
        ),
        "s3": _FakeClient({"get_object": lambda **_: {"Body": io.BytesIO(b"#!/bin/bash\nPASSWORD=s3cr3t\necho hi\n")}}),
        "efs": _FakeClient(
            {
                "describe_file_systems": {"FileSystems": [{"FileSystemId": "fs-efs"}]},
                "describe_mount_targets": {"MountTargets": [{"MountTargetId": "fsmt-1", "SubnetId": "subnet-1"}]},
                "describe_mount_target_security_groups": {"SecurityGroups": ["sg-efs"]},
            }
        ),
        "fsx": _FakeClient(
            {
                "describe_file_systems": {"FileSystems": [{"FileSystemId": "fs-fsx"}]},
                "describe_volumes": {"Volumes": [{"VolumeId": "fsvol-1"}]},
            }
        ),
    }
    clients.update(overrides)
    return clients


class _FakeResponse:
    """An HTTP response with a status, headers and a body."""

    def __init__(self, status, headers, body):
        self.status, self.reason, self._headers, self._body = status, "Reason", headers, body

    def getheader(self, name):
        return self._headers.get(name)

    def read(self, limit):
        return self._body[:limit]


def _fake_https(responses, requests=None):
    """Return a fake HTTPSConnection answering ``responses``, keyed by (host, path), and recording the requests."""

    class _FakeConnection:
        def __init__(self, host, port, timeout):
            self.host = host
            self.path = None

        def request(self, method, path):
            self.path = path
            if requests is not None:
                requests.append((method, self.host, path))

        def getresponse(self):
            response = responses[(self.host, self.path)]
            if isinstance(response, Exception):
                raise response
            return _FakeResponse(*response)

        def close(self):
            pass

    return _FakeConnection


@pytest.fixture
def clients(monkeypatch):
    """Patch boto3, IMDS and HTTPS so that the reader uses fake clients, and return the clients."""
    fakes = _clients()
    monkeypatch.setattr(referenced_resources.boto3, "client", lambda service, **_: fakes[service])
    monkeypatch.setattr(referenced_resources.imds, "get_iam_role_name", stub_returning("my-node-role"))
    monkeypatch.setitem(
        referenced_resources._CONNECTIONS,
        "https",
        _fake_https({("example.com", "/configured.sh"): (200, {}, b"echo configured\n")}),
    )
    return fakes


def test_read_collects_every_referenced_resource(clients):
    reader = ResourceReader("us-east-1")

    resources = reader.read(_CONFIG, "my-cluster", "i-1")

    assert reader.failures == []
    # From the configuration, the node, the stack and the EFS mount targets, each read once.
    assert [group["GroupId"] for group in resources["security_groups"]] == [
        "sg-compute",
        "sg-efs",
        "sg-head",
        "sg-node",
        "sg-queue",
    ]
    assert resources["security_groups"][0]["IpPermissions"] == [{"IpProtocol": "-1"}]
    # From the configuration and the node, with their route table, explicit or main, and network ACL.
    assert [subnet["SubnetId"] for subnet in resources["subnets"]] == ["subnet-1", "subnet-node"]
    assert resources["subnets"][0] == {
        "SubnetId": "subnet-1",
        "VpcId": "vpc-1",
        "CidrBlock": "10.0.0.0/24",
        "RouteTableId": "rtb-subnet-1",
        "NetworkAclId": "acl-1",
    }
    assert resources["subnets"][1]["RouteTableId"] == "rtb-main"
    # Listed once, without their associations, which list every subnet using them.
    assert resources["route_tables"] == [{"RouteTableId": "rtb-main"}, {"RouteTableId": "rtb-subnet-1"}]
    assert resources["network_acls"] == [{"NetworkAclId": "acl-1"}]
    assert resources["launch_templates"] == []
    assert resources["vpcs"] == [{"VpcId": "vpc-1", "VpcEndpoints": [{"ServiceName": "com.amazonaws.us-east-1.s3"}]}]
    assert resources["iam_instance_profiles"] == [
        {"InstanceProfileName": "my-compute-profile", "Arn": _PROFILE_ARN, "Roles": ["my-compute-role"]}
    ]
    assert [role["RoleName"] for role in resources["iam_roles"]] == ["my-compute-role", "my-head-role", "my-node-role"]
    assert resources["iam_roles"][0]["AttachedPolicies"] == [_POLICY_ARN]
    assert resources["iam_roles"][0]["InlinePolicies"] == [
        {"PolicyName": "inline", "PolicyDocument": {"Statement": []}}
    ]
    # The policies of the configuration and of the roles are read once; the AWS managed ones are only listed.
    assert resources["iam_policies"] == [
        {"PolicyArn": _POLICY_ARN, "PolicyDocument": {"Statement": [{"Effect": "Allow"}]}},
        {"PolicyArn": _AWS_POLICY_ARN},
    ]
    assert resources["custom_action_scripts"] == [
        {"Url": "https://example.com/configured.sh", "Truncated": False, "Content": ["echo configured"]},
        {
            "Url": "s3://my-bucket/start.sh",
            "Truncated": False,
            "Content": ["#!/bin/bash", "PASSWORD=<redacted>", "echo hi"],
        },
    ]
    # Only the storage the cluster did not create, the one with an id.
    assert resources["shared_storage"] == [
        {
            "Name": "efs",
            "StorageType": "Efs",
            "FileSystemId": "fs-efs",
            "Description": {"FileSystemId": "fs-efs"},
            "MountTargets": [{"MountTargetId": "fsmt-1", "SubnetId": "subnet-1", "SecurityGroups": ["sg-efs"]}],
        },
        {
            "Name": "fsx",
            "StorageType": "FsxLustre",
            "FileSystemId": "fs-fsx",
            "Description": {"FileSystemId": "fs-fsx"},
        },
        {"Name": "ontap", "StorageType": "FsxOntap", "VolumeId": "fsvol-1", "Description": {"VolumeId": "fsvol-1"}},
    ]
    assert ("get_object", {"Bucket": "my-bucket", "Key": "start.sh"}) in clients["s3"].calls
    assert ("describe_file_systems", {"FileSystemId": "fs-efs"}) in clients["efs"].calls
    assert ("describe_file_systems", {"FileSystemIds": ["fs-fsx"]}) in clients["fsx"].calls


def test_read_records_the_resources_that_cannot_be_read(clients, monkeypatch):
    fakes = _clients(
        ec2=_FakeClient(
            {
                "describe_instances": _access_denied("DescribeInstances"),
                "describe_security_groups": _access_denied("DescribeSecurityGroups"),
                "describe_subnets": _access_denied("DescribeSubnets"),
                "describe_route_tables": _access_denied("DescribeRouteTables"),
                "describe_network_acls": _access_denied("DescribeNetworkAcls"),
            }
        ),
        iam=_FakeClient(
            {
                "get_instance_profile": _access_denied("GetInstanceProfile"),
                "get_role": _access_denied("GetRole"),
                "get_policy": _access_denied("GetPolicy"),
            }
        ),
        efs=_FakeClient(
            {
                "describe_file_systems": _access_denied("DescribeFileSystems"),
                "describe_mount_targets": {"MountTargets": [{"MountTargetId": "fsmt-1"}]},
                "describe_mount_target_security_groups": _access_denied("DescribeMountTargetSecurityGroups"),
            }
        ),
    )
    monkeypatch.setattr(referenced_resources.boto3, "client", lambda service, **_: fakes[service])
    reader = ResourceReader("us-east-1")

    resources = reader.read(_CONFIG, "my-cluster", "i-1")

    assert resources["security_groups"][0] == {
        "GroupId": "sg-compute",
        "Errors": ["ec2:DescribeSecurityGroups: {}".format(_access_denied("DescribeSecurityGroups"))],
    }
    assert resources["iam_instance_profiles"][0]["Errors"]
    assert "Role" not in resources["iam_roles"][0]
    assert "SecurityGroups" not in resources["shared_storage"][0]["MountTargets"][0]
    # Without the VPC of the subnets, their VPC endpoints are not read.
    assert set(resources["subnets"][0]) == {"SubnetId", "Errors"}
    assert resources["vpcs"] == []
    assert set(reader.failures) == {
        ReadFailure("ec2:DescribeInstances", "AccessDenied"),
        ReadFailure("ec2:DescribeSecurityGroups", "AccessDenied"),
        ReadFailure("ec2:DescribeSubnets", "AccessDenied"),
        ReadFailure("ec2:DescribeRouteTables", "AccessDenied"),
        ReadFailure("ec2:DescribeNetworkAcls", "AccessDenied"),
        ReadFailure("iam:GetInstanceProfile", "AccessDenied"),
        ReadFailure("iam:GetRole", "AccessDenied"),
        ReadFailure("iam:GetPolicy", "AccessDenied"),
        ReadFailure("elasticfilesystem:DescribeFileSystems", "AccessDenied"),
        ReadFailure("elasticfilesystem:DescribeMountTargetSecurityGroups", "AccessDenied"),
    }


def test_read_records_a_connection_error_with_its_type(clients, monkeypatch):
    error = EndpointConnectionError(endpoint_url="https://ec2.us-east-1.amazonaws.com")
    fakes = _clients(ec2=_FakeClient({"describe_instances": error, "describe_security_groups": error}))
    monkeypatch.setattr(referenced_resources.boto3, "client", lambda service, **_: fakes[service])
    reader = ResourceReader("us-east-1")

    reader.read({}, None, "i-1")

    assert reader.failures == [ReadFailure("ec2:DescribeInstances", "EndpointConnectionError")]


@pytest.mark.parametrize(
    "error, expected_failures",
    [
        pytest.param(
            ClientError({"Error": {"Code": "ValidationError"}}, "DescribeStackResource"), [], id="no such resource"
        ),
        pytest.param(
            _access_denied("DescribeStackResource"),
            [ReadFailure("cloudformation:DescribeStackResource", "AccessDenied")] * 2,
            id="access denied",
        ),
        pytest.param(
            EndpointConnectionError(endpoint_url="https://cloudformation"),
            [
                ReadFailure(
                    "cloudformation:DescribeStackResource",
                    "Could not connect to the endpoint URL: " '"https://cloudformation"',
                )
            ]
            * 2,
            id="connection error",
        ),
    ],
)
def test_read_records_only_real_errors_reading_the_managed_security_groups(
    clients, monkeypatch, error, expected_failures
):
    fakes = _clients(cloudformation=_FakeClient({"describe_stack_resource": error}))
    monkeypatch.setattr(referenced_resources.boto3, "client", lambda service, **_: fakes[service])
    reader = ResourceReader("us-east-1")

    resources = reader.read({}, "my-cluster", None)

    assert resources["security_groups"] == []
    assert reader.failures == expected_failures


def test_read_without_stack_and_instance_reads_only_the_configuration(clients):
    reader = ResourceReader("us-east-1")

    resources = reader.read({"HeadNode": {"Networking": {"SecurityGroups": ["sg-head"]}}}, None, None)

    assert [group["GroupId"] for group in resources["security_groups"]] == ["sg-head"]
    assert clients["cloudformation"].calls == []
    assert [operation for operation, _ in clients["ec2"].calls] == ["describe_security_groups"]


@pytest.mark.parametrize("role, expected_roles", [(None, []), ("my-node-role", ["my-node-role"])])
def test_read_includes_the_role_of_the_node_when_it_has_one(clients, monkeypatch, role, expected_roles):
    monkeypatch.setattr(referenced_resources.imds, "get_iam_role_name", stub_returning(role))

    resources = ResourceReader("us-east-1").read({}, None, None)

    assert [entry["RoleName"] for entry in resources["iam_roles"]] == expected_roles


def test_read_without_imds_still_reads_the_roles_of_the_configuration(clients, monkeypatch, caplog):
    monkeypatch.setattr(referenced_resources.imds, "get_iam_role_name", stub_raising(OSError("timed out")))

    resources = ResourceReader("us-east-1").read({"HeadNode": {"Iam": {"InstanceRole": _ROLE_ARN}}}, None, None)

    assert [entry["RoleName"] for entry in resources["iam_roles"]] == ["my-head-role"]
    assert "Could not read the IAM role of the node from IMDS: timed out" in caplog.text


@pytest.mark.parametrize(
    "denied, expected_keys",
    [
        pytest.param("list_attached_role_policies", {"RoleName", "Role", "Errors", "InlinePolicies"}, id="attached"),
        pytest.param("list_role_policies", {"RoleName", "Role", "Errors", "AttachedPolicies"}, id="inline"),
        pytest.param(
            "get_role_policy", {"RoleName", "Role", "AttachedPolicies", "InlinePolicies"}, id="inline document"
        ),
    ],
)
def test_role_policies_that_cannot_be_listed_are_recorded(clients, monkeypatch, denied, expected_keys):
    clients["iam"]._responses[denied] = _access_denied(denied)
    monkeypatch.setattr(referenced_resources.imds, "get_iam_role_name", stub_returning("r"))

    role = ResourceReader("us-east-1").read({}, None, None)["iam_roles"][0]

    assert set(role) == expected_keys
    if denied == "get_role_policy":
        assert role["InlinePolicies"] == [{"PolicyName": "inline", "Errors": [_error_message(denied)]}]


def _error_message(operation):
    action = "iam:" + "".join(part.capitalize() for part in operation.split("_"))
    return "{}: {}".format(action, _access_denied(operation))


def test_policy_version_that_cannot_be_read_is_recorded(clients, monkeypatch):
    clients["iam"]._responses["get_policy_version"] = _access_denied("GetPolicyVersion")
    config = {"HeadNode": {"Iam": {"AdditionalIamPolicies": [{"Policy": _POLICY_ARN}, {}, "not-a-dict"]}}}
    monkeypatch.setattr(referenced_resources.imds, "get_iam_role_name", stub_returning(None))

    resources = ResourceReader("us-east-1").read(config, None, None)

    assert resources["iam_policies"] == [
        {
            "PolicyArn": _POLICY_ARN,
            "Errors": ["iam:GetPolicyVersion: {}".format(_access_denied("GetPolicyVersion"))],
        }
    ]


def _script_config(url):
    return {"HeadNode": {"CustomActions": {"OnNodeStart": {"Script": url}, "OnNodeUpdated": None}}}


def test_script_larger_than_the_limit_is_truncated(clients, monkeypatch):
    monkeypatch.setattr(referenced_resources, "CUSTOM_ACTION_SCRIPT_MAX_BYTES", 8)
    clients["s3"]._responses["get_object"] = lambda **_: {"Body": io.BytesIO(b"line one\nline two\n")}

    script = ResourceReader("us-east-1").read(_script_config("s3://b/k.sh"), None, None)["custom_action_scripts"][0]

    assert script == {"Url": "s3://b/k.sh", "Truncated": True, "Content": ["line one"]}


def test_https_script_follows_redirects_as_the_custom_action_executor(clients, monkeypatch):
    requests = []
    responses = {
        ("example.com", "/a.sh?v=1"): (302, {"Location": "https://cdn.example.com/a.sh"}, b""),
        ("cdn.example.com", "/a.sh"): (301, {"Location": "http://mirror.example.com/a.sh"}, b""),
        ("mirror.example.com", "/a.sh"): (307, {"Location": "/b.sh"}, b""),
        ("mirror.example.com", "/b.sh"): (200, {}, b"echo b\n"),
    }
    connection = _fake_https(responses, requests)
    monkeypatch.setitem(referenced_resources._CONNECTIONS, "https", connection)
    monkeypatch.setitem(referenced_resources._CONNECTIONS, "http", connection)

    script = ResourceReader("us-east-1").read(_script_config("https://example.com/a.sh?v=1"), None, None)[
        "custom_action_scripts"
    ][0]

    assert script["Content"] == ["echo b"]
    assert requests == [
        ("GET", "example.com", "/a.sh?v=1"),
        ("GET", "cdn.example.com", "/a.sh"),
        ("GET", "mirror.example.com", "/a.sh"),
        ("GET", "mirror.example.com", "/b.sh"),
    ]


@pytest.mark.parametrize(
    "responses, expected_error, expected_failure",
    [
        pytest.param(
            {("example.com", "/a.sh"): OSError("Name or service not known")},
            "Name or service not known",
            "OSError",
            id="connection error",
        ),
        pytest.param({("example.com", "/a.sh"): (404, {}, b"")}, "HTTP 404 Reason", "OSError", id="error status"),
        pytest.param(
            {("example.com", "/a.sh"): (302, {"Location": "file:///etc/shadow"}, b"")},
            "the URL must be an HTTPS or HTTP URL: file:///etc/shadow",
            "OSError",
            id="redirect to another scheme",
        ),
        pytest.param(
            {("example.com", "/a.sh"): (302, {"Location": "/a.sh"}, b"")},
            "too many redirects",
            "OSError",
            id="redirect loop",
        ),
        pytest.param(
            {("example.com", "/a.sh"): http.client.RemoteDisconnected("Remote end closed connection")},
            "Remote end closed connection",
            "RemoteDisconnected",
            id="protocol error",
        ),
    ],
)
def test_https_script_that_cannot_be_downloaded_is_recorded(
    clients, monkeypatch, responses, expected_error, expected_failure
):
    monkeypatch.setitem(referenced_resources._CONNECTIONS, "https", _fake_https(responses))
    reader = ResourceReader("us-east-1")

    script = reader.read(_script_config("https://example.com/a.sh"), None, None)["custom_action_scripts"][0]

    assert script == {"Url": "https://example.com/a.sh", "Errors": [expected_error]}
    assert reader.failures == [ReadFailure("https:GET", expected_failure)]


def test_s3_script_that_cannot_be_read_is_recorded(clients):
    clients["s3"]._responses["get_object"] = _access_denied("GetObject")
    reader = ResourceReader("us-east-1")

    script = reader.read(_script_config("s3://b/k.sh"), None, None)["custom_action_scripts"][0]

    assert "Content" not in script
    assert reader.failures == [ReadFailure("s3:GetObject", "AccessDenied")]


def test_script_with_another_scheme_is_not_read(clients):
    script = ResourceReader("us-east-1").read(_script_config("http://example.com/a.sh"), None, None)[
        "custom_action_scripts"
    ][0]

    assert script == {"Url": "http://example.com/a.sh", "Errors": ["the URL must be an S3 or HTTPS URL"]}


def test_subnet_without_route_table_or_network_acl_has_none(clients):
    clients["ec2"]._responses["describe_route_tables"] = {"RouteTables": []}
    clients["ec2"]._responses["describe_network_acls"] = {"NetworkAcls": []}
    clients["ec2"]._responses["describe_vpc_endpoints"] = _access_denied("DescribeVpcEndpoints")
    reader = ResourceReader("us-east-1")

    resources = reader.read({"HeadNode": {"Networking": {"SubnetId": "subnet-1"}}}, None, None)

    assert set(resources["subnets"][0]) == {"SubnetId", "VpcId", "CidrBlock"}
    assert (resources["route_tables"], resources["network_acls"]) == ([], [])
    assert set(resources["vpcs"][0]) == {"VpcId", "Errors"}
    assert reader.failures == [ReadFailure("ec2:DescribeVpcEndpoints", "AccessDenied")]


_LAUNCH_TEMPLATES_CONFIG = {
    "Queues": {
        "q1": {
            "ComputeResources": {
                "cr1": {"LaunchTemplate": {"Id": "lt-cr1", "Version": 3, "LogicalId": "LaunchTemplateA"}},
                "cr2": {"LaunchTemplate": {}},
            }
        }
    },
    "LoginPools": {"pool": {"LaunchTemplate": {"Name": "my-cluster-pool", "Version": "$Latest"}}},
}


def _launch_template_versions(Versions, LaunchTemplateId=None, LaunchTemplateName=None):  # noqa: N803
    """Return a compute launch template with security groups on its interface, and a login one on the template."""
    if LaunchTemplateId == "lt-cr1":
        data = {
            "InstanceType": "c5.xlarge",
            "UserData": "IyEvYmluL2Jhc2g=",
            "IamInstanceProfile": {"Arn": "arn:aws:iam::123456789012:instance-profile/parallelcluster/c/cr1-profile"},
            "NetworkInterfaces": [{"DeviceIndex": 0, "Groups": ["sg-compute-lt"]}],
        }
    elif LaunchTemplateName == "my-cluster-pool":
        data = {"IamInstanceProfile": {"Name": "pool-profile"}, "SecurityGroupIds": ["sg-login"]}
    else:
        return ClientError({"Error": {"Code": "InvalidLaunchTemplateId.Malformed"}}, "DescribeLaunchTemplateVersions")
    return {"LaunchTemplateVersions": [{"VersionNumber": 3, "LaunchTemplateData": data}]}


def test_read_collects_the_launch_templates_of_the_nodes(clients, tmp_path):
    path = tmp_path / "launch-templates-config.json"
    path.write_text(json.dumps(_LAUNCH_TEMPLATES_CONFIG))
    clients["ec2"]._responses["describe_launch_template_versions"] = _launch_template_versions
    reader = ResourceReader("us-east-1")

    resources = reader.read({}, None, None, str(path))

    # The user data, the same bootstrap script for every node, is left out.
    assert resources["launch_templates"][0] == {
        "Queue": "q1",
        "ComputeResource": "cr1",
        "LaunchTemplateId": "lt-cr1",
        "Version": "3",
        "LaunchTemplateData": {
            "InstanceType": "c5.xlarge",
            "IamInstanceProfile": {"Arn": "arn:aws:iam::123456789012:instance-profile/parallelcluster/c/cr1-profile"},
            "NetworkInterfaces": [{"DeviceIndex": 0, "Groups": ["sg-compute-lt"]}],
        },
    }
    assert resources["launch_templates"][1]["Errors"]
    assert resources["launch_templates"][2]["LoginPool"] == "pool"
    assert (
        "describe_launch_template_versions",
        {"Versions": ["$Latest"], "LaunchTemplateName": "my-cluster-pool"},
    ) in (clients["ec2"].calls)
    # The security groups and the instance profiles, with their roles, the nodes launch with.
    assert [group["GroupId"] for group in resources["security_groups"]] == ["sg-compute-lt", "sg-login"]
    assert [profile["InstanceProfileName"] for profile in resources["iam_instance_profiles"]] == [
        "cr1-profile",
        "pool-profile",
    ]
    assert [role["RoleName"] for role in resources["iam_roles"]] == ["cr1-role", "my-node-role", "pool-role"]


@pytest.mark.parametrize("content", [None, "not json"])
def test_launch_templates_config_that_cannot_be_read_is_recorded(clients, tmp_path, caplog, content):
    path = tmp_path / "launch-templates-config.json"
    if content is not None:
        path.write_text(content)
    reader = ResourceReader("us-east-1")

    resources = reader.read({}, None, None, str(path))

    assert resources["launch_templates"] == []
    assert reader.failures == [ReadFailure(str(path), "FileNotFoundError" if content is None else "JSONDecodeError")]
    assert "Could not read the launch templates config" in caplog.text


def test_launch_template_without_instance_profile_adds_none(clients, tmp_path):
    path = tmp_path / "launch-templates-config.json"
    path.write_text(json.dumps({"Queues": {"q1": {"ComputeResources": {"cr1": {"LaunchTemplate": {"Id": "lt-1"}}}}}}))
    clients["ec2"]._responses["describe_launch_template_versions"] = {
        "LaunchTemplateVersions": [{"LaunchTemplateData": {"IamInstanceProfile": {}}}]
    }
    clients["iam"]._responses["get_instance_profile"] = _access_denied("GetInstanceProfile")

    resources = ResourceReader("us-east-1").read({}, None, None, str(path))

    assert resources["launch_templates"][0]["Version"] == "$Latest"
    assert resources["iam_instance_profiles"] == []
