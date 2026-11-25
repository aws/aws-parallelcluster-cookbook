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

"""Unit tests for the cluster update history check."""

from datetime import datetime, timezone

import pytest

from pcluster_diag.checks import cluster_update_history as check_module
from pcluster_diag.checks.cluster_update_history import ClusterUpdateHistory
from pcluster_diag.models.context import NodeType
from pcluster_diag.models.result import Status
from tests.sample_data import sample_context
from tests.stubs import stub_raising, stub_returning

_UPDATED = datetime(2026, 10, 12, 14, 10, 5, tzinfo=timezone.utc)
_LOG = [
    "[2026-09-30T08:15:00+00:00] INFO: *** Cinc Client ***",
    "[2026-10-05T10:20:31+00:00] INFO: Overridden Run List: [recipe[aws-parallelcluster-entrypoints::update]]",
    "[2026-10-05T10:20:32+00:00] INFO: Changeset is:",
    '{"changeSet": [{"parameter": "MinCount", "requestedValue": 1, "currentValue": 0}]}',
]


def _context():
    context = sample_context()
    context.dna_json = {"cluster": {"node_type": "HeadNode", "stack_name": "my-cluster", "region": "us-east-1"}}
    return context


@pytest.fixture
def history(monkeypatch):
    """Patch /var/log/chef-client.log with one successful update, and the stack status with UPDATE_COMPLETE."""
    monkeypatch.setattr(check_module.log_files, "read_rotated_log", stub_returning(_LOG))
    monkeypatch.setattr(check_module.cfn, "get_stack_status", stub_returning(("UPDATE_COMPLETE", _UPDATED)))


def test_should_run_only_on_the_head_node():
    assert ClusterUpdateHistory().should_run(sample_context(NodeType.HEAD)) is True
    assert ClusterUpdateHistory().should_run(sample_context(NodeType.COMPUTE)) is False


def test_reports_the_history_and_the_stack_status(history):
    result = ClusterUpdateHistory().run(_context())

    assert result.status == Status.PASSED
    history_info, stack_info = result.infos
    assert history_info.code == "I1"
    assert history_info.message == (
        "1 cluster update runs since 2026-09-30T08:15:00+00:00; the latest, at 2026-10-05T10:20:31+00:00, succeeded."
    )
    assert result.details == [
        {
            "time": "2026-10-05T10:20:31+00:00",
            "outcome": "succeeded",
            "changeSet": [{"parameter": "MinCount", "requestedValue": 1, "currentValue": 0}],
        }
    ]
    assert stack_info.message == "Current stack status: UPDATE_COMPLETE (last updated 2026-10-12T14:10:05+00:00)."


@pytest.mark.parametrize("status", ["UPDATE_ROLLBACK_COMPLETE", "UPDATE_ROLLBACK_FAILED", "UPDATE_FAILED"])
def test_warns_when_the_latest_update_did_not_complete(history, monkeypatch, status):
    monkeypatch.setattr(check_module.cfn, "get_stack_status", stub_returning((status, _UPDATED)))

    result = ClusterUpdateHistory().run(_context())

    assert result.status == Status.WARNING
    (warning,) = result.warnings
    assert warning.message == (
        "The latest cluster update did not complete: stack status {} (last updated 2026-10-12T14:10:05+00:00).".format(
            status
        )
    )


def test_stack_status_is_omitted_when_it_cannot_be_read(history, monkeypatch):
    monkeypatch.setattr(check_module.cfn, "get_stack_status", stub_raising("AccessDenied"))

    result = ClusterUpdateHistory().run(_context())

    assert result.status == Status.PASSED
    assert [info.code for info in result.infos] == ["I1"]


@pytest.mark.parametrize(
    "log, expected",
    [
        (_LOG[:1], "No cluster update found in /var/log/chef-client.log since 2026-09-30T08:15:00+00:00."),
        ([], "No cluster update found in /var/log/chef-client.log."),
    ],
)
def test_no_update_in_the_log(history, monkeypatch, log, expected):
    monkeypatch.setattr(check_module.log_files, "read_rotated_log", stub_returning(log))

    result = ClusterUpdateHistory().run(_context())

    assert result.infos[0].message == expected


def test_missing_log_is_a_check_error(history, monkeypatch):
    monkeypatch.setattr(
        check_module.log_files, "read_rotated_log", stub_raising(FileNotFoundError("the file does not exist"))
    )

    result = ClusterUpdateHistory().run(_context())

    assert result.status == Status.CHECK_ERROR
    assert result.errors[0].message == (
        "Could not read the cluster update history from /var/log/chef-client.log: the file does not exist."
    )
