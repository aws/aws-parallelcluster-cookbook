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

"""Unit tests for the configuration dump checks."""

import pytest

from pcluster_diag.checks import configuration_dump
from pcluster_diag.checks.configuration_dump import CoreSettings, ReferencedResources
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from pcluster_diag.util.config_files import ConfigFile
from pcluster_diag.util.referenced_resources import ReadFailure
from tests.sample_data import sample_context
from tests.stubs import stub_returning


def test_core_settings_are_dumped_with_secrets_redacted(tmp_path, monkeypatch):
    (tmp_path / "slurmdbd.conf").write_text("StorageHost=db.example.com\nStoragePass=s3cr3t\n")
    (tmp_path / "slurm.conf").write_text("ClusterName=my-cluster\n")
    monkeypatch.setattr(configuration_dump, "CORE_SETTINGS_FILE_PATTERNS", (str(tmp_path / "*.conf"),))

    result = CoreSettings().run(sample_context())

    assert result.status is Status.PASSED
    assert [info.message for info in result.infos] == ["Collected 2 configuration files, with their secrets redacted."]
    assert result.details == (
        "==> {0}/slurm.conf <==\nClusterName=my-cluster\n\n"
        "==> {0}/slurmdbd.conf <==\nStorageHost=db.example.com\nStoragePass=<redacted>\n".format(tmp_path)
    )


def test_core_settings_report_the_unreadable_files(monkeypatch):
    files = [ConfigFile("/etc/fstab", content="x\n"), ConfigFile("/etc/sssd/sssd.conf", error="Permission denied")]
    monkeypatch.setattr(configuration_dump.config_files, "read_config_files", stub_returning(files))

    result = CoreSettings().run(sample_context())

    assert result.status is Status.CHECK_ERROR
    assert [error.message for error in result.errors] == ["Could not read /etc/sssd/sssd.conf: Permission denied."]
    assert "<could not read: Permission denied>" in result.details


def test_core_settings_without_files_has_no_details(monkeypatch):
    monkeypatch.setattr(configuration_dump, "CORE_SETTINGS_FILE_PATTERNS", ())

    result = CoreSettings().run(sample_context())

    assert result.infos[0].message == "Collected 0 configuration files, with their secrets redacted."
    assert result.details is None


@pytest.mark.parametrize(
    "node_type, expected", [(NodeType.HEAD, True), (NodeType.COMPUTE, False), (NodeType.LOGIN, False)]
)
def test_referenced_resources_run_only_on_the_head_node(node_type, expected):
    assert ReferencedResources().should_run(sample_context(node_type)) is expected


def test_referenced_resources_are_opt_in():
    assert ReferencedResources().approval_required(sample_context(NodeType.HEAD)) is True


class _FakeReader:
    """A ResourceReader returning canned resources and failures, and recording what it is asked to read."""

    instances = []

    def __init__(self, region, failures=()):
        self.region = region
        self.failures = list(failures)
        self.read_args = None
        _FakeReader.instances.append(self)

    def read(self, cluster_config, stack_name, instance_id, launch_templates_path):
        self.read_args = (cluster_config, stack_name, instance_id, launch_templates_path)
        return {
            "launch_templates": [{"Queue": "q1"}],
            "security_groups": [{"GroupId": "sg-1"}, {"GroupId": "sg-2"}],
            "subnets": [{"SubnetId": "subnet-1"}],
            "iam_instance_profiles": [],
            "iam_roles": [{"RoleName": "r"}],
            "iam_policies": [],
            "custom_action_scripts": [{"Url": "s3://b/k.sh"}],
            "shared_storage": [],
        }


def _patch_reader(monkeypatch, failures=()):
    _FakeReader.instances = []
    monkeypatch.setattr(configuration_dump, "ResourceReader", lambda region: _FakeReader(region, failures))


def _head_context():
    context = sample_context(NodeType.HEAD)
    context.dna_json = {"cluster": {"region": "eu-west-1", "stack_name": "my-cluster"}}
    return context


def test_referenced_resources_are_dumped(monkeypatch):
    _patch_reader(monkeypatch)
    context = _head_context()

    result = ReferencedResources().run(context)

    reader = _FakeReader.instances[0]
    assert reader.region == "eu-west-1"
    assert reader.read_args == (
        context.cluster_config,
        "my-cluster",
        context.instance_id,
        "/opt/parallelcluster/shared/launch-templates-config.json",
    )
    assert result.status is Status.PASSED
    assert [info.message for info in result.infos] == [
        "Collected 1 launch templates, 2 security groups, 1 subnets, 1 IAM roles, 0 IAM policies, 1 custom action "
        "scripts and 0 existing shared storage."
    ]
    assert result.details["security_groups"] == [{"GroupId": "sg-1"}, {"GroupId": "sg-2"}]


def test_missing_permissions_and_other_read_failures_are_warnings(monkeypatch):
    failures = [
        ReadFailure("ec2:DescribeSecurityGroups", "UnauthorizedOperation"),
        ReadFailure("ec2:DescribeSecurityGroups", "UnauthorizedOperation"),
        ReadFailure("iam:GetRole", "AccessDenied"),
        ReadFailure("elasticfilesystem:DescribeFileSystems", "AccessDeniedException"),
        ReadFailure("ec2:DescribeSubnets", "RequestLimitExceeded"),
        ReadFailure("https:GET", "OSError"),
        ReadFailure("ec2:DescribeRouteTables", "RequestLimitExceeded"),
    ]
    _patch_reader(monkeypatch, failures)

    result = ReferencedResources().run(_head_context())

    assert result.status is Status.WARNING
    assert [(warning.code, warning.message) for warning in result.warnings] == [
        (
            "W1",
            "The credentials do not allow reading some resources, which are recorded with their error: "
            "ec2:DescribeSecurityGroups, iam:GetRole, elasticfilesystem:DescribeFileSystems. To collect them, run "
            "pcluster-diag with credentials that allow these actions.",
        ),
        (
            "W2",
            "Some resources could not be read, and are recorded with their error: RequestLimitExceeded "
            "(ec2:DescribeSubnets, ec2:DescribeRouteTables); OSError (https:GET).",
        ),
    ]
    assert result.details["security_groups"] == [{"GroupId": "sg-1"}, {"GroupId": "sg-2"}]


@pytest.mark.parametrize(
    "failure, expected_code",
    [
        pytest.param(ReadFailure("iam:GetRole", "AccessDenied"), "W1", id="permission"),
        pytest.param(ReadFailure("https:GET", "OSError"), "W2", id="other"),
    ],
)
def test_a_single_kind_of_read_failure_is_a_single_warning(monkeypatch, failure, expected_code):
    _patch_reader(monkeypatch, [failure])

    result = ReferencedResources().run(_head_context())

    assert [warning.code for warning in result.warnings] == [expected_code]


def test_referenced_resources_without_region_is_a_check_error(monkeypatch):
    _patch_reader(monkeypatch)
    context = _head_context()
    context.dna_json = {"cluster": {}}

    result = ReferencedResources().run(context)

    assert result.status is Status.CHECK_ERROR
    assert result.errors[0].message == "The region of the cluster is not in dna.json: no resource was read."
    assert _FakeReader.instances == []
