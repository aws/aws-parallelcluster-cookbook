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

"""Read the compute fleet status, and parse its changes from the clusterstatusmgtd and clustermgtd logs.

``pcluster update-compute-fleet`` writes START_REQUESTED or STOP_REQUESTED to the cluster DynamoDB table.
clusterstatusmgtd then moves the fleet to STARTING/STOPPING and RUNNING/STOPPED, and clustermgtd moves it to
PROTECTED on repeated bootstrap failures; both log every change they make. The request itself is not logged, but both
daemons log the status they read on every loop, which shows when a request took the fleet out of PROTECTED.
"""

import ast
import re
from datetime import datetime
from typing import List, Optional, Tuple

import boto3

# A clusterstatusmgtd or clustermgtd log line: "2026-10-12 14:30:02,118 - [module:function] - INFO - message".
_LOG_LINE = re.compile(
    r"^(?P<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2},\d{3}) - \[[^\]]*\] - (?P<level>[A-Z]+) - (?P<message>.*)$"
)
_CHANGE = re.compile(r"^Updating compute fleet status from (?P<from>\w+) to (?P<to>\w+)$")
_CURRENT = re.compile(r"^Current compute fleet status: (?P<status>\w+)$")
_INACTIVE_PARTITIONS = "Placing bootstrap failure partitions to INACTIVE: "

PROTECTED = "PROTECTED"
REQUESTED_STATUSES = ("START_REQUESTED", "STOP_REQUESTED")
IN_PROGRESS_STATUSES = ("STARTING", "STOPPING")

# DynamoDB item holding the compute fleet status, as written by the CLI and clusterstatusmgtd.
_FLEET_ITEM_KEY = {"Id": "COMPUTE_FLEET"}


def get_compute_fleet_status(table_name: str, region: str, config=None) -> Tuple[str, Optional[datetime]]:
    """Return the compute fleet status and when it was last updated, from the cluster DynamoDB table.

    Raises:
        LookupError: If the table has no compute fleet status.
    """
    table = boto3.resource("dynamodb", region_name=region, config=config).Table(table_name)
    item = table.get_item(ConsistentRead=True, Key=_FLEET_ITEM_KEY).get("Item")
    data = (item or {}).get("Data") or {}
    if not data.get("status"):
        raise LookupError("the table has no compute fleet status")
    updated = data.get("lastStatusUpdatedTime")
    return data["status"], datetime.fromisoformat(updated) if updated else None


def first_log_time(lines: List[str]) -> Optional[str]:
    """Return the time of the first log line in ``lines``, or None if there is none."""
    times = [match["time"] for match in map(_LOG_LINE.match, lines) if match]
    return min(times) if times else None


def parse_status_changes(lines: List[str]) -> List[dict]:
    """Return the compute fleet status changes logged in ``lines``, ordered by time.

    ``lines`` may mix the lines of several logs. A change to PROTECTED carries the partitions clustermgtd made
    inactive, and a change out of PROTECTED is added when a daemon first reads a start or stop request.
    """
    # The log time format sorts chronologically; the sort is stable, so lines logged at the same time keep their order.
    entries = sorted(
        ((match["time"], match["message"]) for match in map(_LOG_LINE.match, lines) if match), key=lambda e: e[0]
    )
    changes: List[dict] = []
    partitions = None
    protected = False
    for time, message in entries:
        change = _CHANGE.match(message)
        current = _CURRENT.match(message)
        if message.startswith(_INACTIVE_PARTITIONS):
            partitions = _partitions(message[len(_INACTIVE_PARTITIONS) :])
        elif change:
            entry = {"time": time, "from": change["from"], "to": change["to"]}
            if change["to"] == PROTECTED and partitions is not None:
                entry["partitions"] = partitions
            changes.append(entry)
            protected = change["to"] == PROTECTED
        elif current and protected and current["status"] in REQUESTED_STATUSES:
            changes.append({"time": time, "from": PROTECTED, "to": current["status"]})
            protected = False
    return changes


def _partitions(text: str):
    """Return the partitions logged as ``text`` (a Python list), or the text itself if it cannot be parsed."""
    try:
        return ast.literal_eval(text)
    except (ValueError, SyntaxError):
        return text
