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

"""Unit tests for the CloudFormation stack-output helper."""

import pytest

from pcluster_diag.util import cfn


class _FakeCloudFormation:
    def __init__(self, outputs):
        self._outputs = outputs
        self.captured = {}

    def describe_stacks(self, StackName):  # noqa: N803  boto3 uses PascalCase kwargs
        self.captured["StackName"] = StackName
        return {"Stacks": [{"Outputs": self._outputs}]}


def _patch_client(monkeypatch, fake):
    captured = {}

    def fake_client(service, region_name):
        captured.update(service=service, region_name=region_name)
        return fake

    monkeypatch.setattr(cfn.boto3, "client", fake_client)
    return captured


def test_get_stack_output_returns_matching_output_value(monkeypatch):
    fake = _FakeCloudFormation(
        [{"OutputKey": "Other", "OutputValue": "x"}, {"OutputKey": "HeadNodeInstanceID", "OutputValue": "i-headnode"}]
    )
    captured = _patch_client(monkeypatch, fake)

    value = cfn.get_stack_output("my-stack", "eu-west-1", "HeadNodeInstanceID")

    assert value == "i-headnode"
    assert captured == {"service": "cloudformation", "region_name": "eu-west-1"}
    assert fake.captured["StackName"] == "my-stack"


def test_get_stack_output_raises_when_output_absent(monkeypatch):
    _patch_client(monkeypatch, _FakeCloudFormation([{"OutputKey": "Other", "OutputValue": "x"}]))

    with pytest.raises(KeyError):
        cfn.get_stack_output("my-stack", "eu-west-1", "HeadNodeInstanceID")
