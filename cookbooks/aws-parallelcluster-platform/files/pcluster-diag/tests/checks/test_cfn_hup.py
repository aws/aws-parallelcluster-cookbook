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

"""Unit tests for the cfn-hup check covering description, should_run, approval_required, and run."""

import pytest

from pcluster_diag.checks import cfn_hup
from pcluster_diag.checks.cfn_hup import CfnHupRunsOnlyOnHeadNode
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context


def test_description():
    description = CfnHupRunsOnlyOnHeadNode().description

    assert description == "Verify that the cfn-hup daemon runs only on the head node."


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_should_run(node_type):
    # The check compares actual vs expected state, so it applies on every node type.
    assert CfnHupRunsOnlyOnHeadNode().should_run(sample_context(node_type)) is True


@pytest.mark.parametrize("node_type", list(NodeType), ids=lambda nt: nt.name)
def test_approval_required(node_type):
    assert CfnHupRunsOnlyOnHeadNode().approval_required(sample_context(node_type)) is False


@pytest.mark.parametrize(
    "node_type, is_running, expected_status, expected_message",
    [
        (NodeType.HEAD, True, Status.PASSED, None),  # head: running as expected
        (
            NodeType.HEAD,
            False,
            Status.FAILURE,
            "cfn-hup is not running on the HeadNode.",
        ),  # head: should run but isn't
        (NodeType.COMPUTE, False, Status.PASSED, None),  # compute: not running as expected
        (
            NodeType.COMPUTE,
            True,
            Status.FAILURE,
            "cfn-hup is running on the ComputeFleet.",
        ),  # compute: running but shouldn't be
        (NodeType.LOGIN, False, Status.PASSED, None),  # login: not running as expected
        (
            NodeType.LOGIN,
            True,
            Status.FAILURE,
            "cfn-hup is running on the LoginNode.",
        ),  # login: running but shouldn't be
    ],
)
def test_run(monkeypatch, node_type, is_running, expected_status, expected_message):
    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", lambda _program: is_running)

    result = CfnHupRunsOnlyOnHeadNode().run(sample_context(node_type))

    assert result.status is expected_status
    assert result.message == expected_message


def test_run_propagates_when_status_cannot_be_determined(monkeypatch):
    # An undeterminable status makes the check raise (the Runner maps it to an ERROR).
    def _raise(_program):
        raise RuntimeError("cannot determine status")

    monkeypatch.setattr(cfn_hup, "is_supervisord_program_running", _raise)

    with pytest.raises(RuntimeError):
        CfnHupRunsOnlyOnHeadNode().run(sample_context(NodeType.HEAD))
