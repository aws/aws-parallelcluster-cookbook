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

"""Unit tests for the compute fleet status helpers."""

from datetime import datetime, timezone

import pytest

from pcluster_diag.util import fleet_status


def _line(time, message, logger="clusterstatusmgtd:_update_compute_fleet_status"):
    return "{} - [{}] - INFO - {}".format(time, logger, message)


def _change(time, from_status, to_status, logger="clusterstatusmgtd:_update_compute_fleet_status"):
    return _line(time, "Updating compute fleet status from {} to {}".format(from_status, to_status), logger)


def test_parse_status_changes_merges_the_logs_by_time():
    clusterstatusmgtd = [
        _change("2026-10-05 10:15:01,322", "STOP_REQUESTED", "STOPPING"),
        _change("2026-10-05 10:15:40,871", "STOPPING", "STOPPED"),
    ]
    clustermgtd = [
        _change("2026-10-05 10:15:20,000", "RUNNING", "PROTECTED", "clustermgtd:_update_compute_fleet_status")
    ]

    changes = fleet_status.parse_status_changes(clusterstatusmgtd + clustermgtd)

    assert [(change["from"], change["to"]) for change in changes] == [
        ("STOP_REQUESTED", "STOPPING"),
        ("RUNNING", "PROTECTED"),
        ("STOPPING", "STOPPED"),
    ]


def test_protected_change_carries_the_partitions_and_the_exit_is_inferred():
    lines = [
        _line(
            "2026-10-12 14:30:02,100", "Placing bootstrap failure partitions to INACTIVE: ['queue']", "clustermgtd:x"
        ),
        _change("2026-10-12 14:30:02,118", "RUNNING", "PROTECTED", "clustermgtd:_update_compute_fleet_status"),
        _line("2026-10-12 14:31:00,000", "Current compute fleet status: PROTECTED", "clusterstatusmgtd:x"),
        _line("2026-10-12 16:05:10,402", "Current compute fleet status: START_REQUESTED", "clusterstatusmgtd:x"),
        _line("2026-10-12 16:06:10,402", "Current compute fleet status: START_REQUESTED", "clusterstatusmgtd:x"),
        _change("2026-10-12 16:06:10,415", "START_REQUESTED", "STARTING"),
    ]

    changes = fleet_status.parse_status_changes(lines)

    assert changes == [
        {"time": "2026-10-12 14:30:02,118", "from": "RUNNING", "to": "PROTECTED", "partitions": ["queue"]},
        {"time": "2026-10-12 16:05:10,402", "from": "PROTECTED", "to": "START_REQUESTED"},
        {"time": "2026-10-12 16:06:10,415", "from": "START_REQUESTED", "to": "STARTING"},
    ]


def test_request_without_protection_is_not_added():
    lines = [_line("2026-10-05 10:15:00,000", "Current compute fleet status: STOP_REQUESTED", "clusterstatusmgtd:x")]

    assert fleet_status.parse_status_changes(lines) == []


class _FakeTable:
    def __init__(self, item):
        self._item = item

    def get_item(self, ConsistentRead, Key):  # noqa: N803  boto3 uses PascalCase kwargs
        assert ConsistentRead is True and Key == {"Id": "COMPUTE_FLEET"}
        return {"Item": self._item} if self._item is not None else {}


def _patch_table(monkeypatch, item):
    class _FakeResource:
        def Table(self, name):  # noqa: N802  boto3 method name
            return _FakeTable(item)

    monkeypatch.setattr(fleet_status.boto3, "resource", lambda *args, **kwargs: _FakeResource())


def test_get_compute_fleet_status(monkeypatch):
    _patch_table(
        monkeypatch,
        {
            "Id": "COMPUTE_FLEET",
            "Data": {"status": "RUNNING", "lastStatusUpdatedTime": "2026-10-12 14:21:40.912+00:00"},
        },
    )

    assert fleet_status.get_compute_fleet_status("table", "us-east-1") == (
        "RUNNING",
        datetime(2026, 10, 12, 14, 21, 40, 912000, tzinfo=timezone.utc),
    )


@pytest.mark.parametrize("item", [None, {"Id": "COMPUTE_FLEET"}])
def test_get_compute_fleet_status_without_status(monkeypatch, item):
    _patch_table(monkeypatch, item)

    with pytest.raises(LookupError):
        fleet_status.get_compute_fleet_status("table", "us-east-1")
