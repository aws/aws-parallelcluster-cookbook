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

"""Generic serialization helpers."""

import dataclasses
import json
from datetime import datetime, timezone
from enum import Enum
from typing import Optional


def to_dict(obj):
    """Convert a dataclass to a JSON-serializable dict, dropping None fields (enums become their value)."""
    return dataclasses.asdict(
        obj,
        dict_factory=lambda items: {
            key: (value.value if isinstance(value, Enum) else value) for key, value in items if value is not None
        },
    )


def to_json(obj, indent: int = 2) -> str:
    """Serialize ``obj`` to a JSON string, preserving dataclass field declaration order."""
    return json.dumps(to_dict(obj), indent=indent, sort_keys=False)


def iso_time(time: Optional[datetime]) -> str:
    """Return ``time`` in UTC, in ISO 8601 to the second (e.g. ``2026-10-12T14:10:05+00:00``), or "unknown" if None.

    A time without a timezone is taken as the local time of the node, as logged by the ParallelCluster daemons.
    """
    return time.astimezone(timezone.utc).isoformat(timespec="seconds") if time else "unknown"


def log_time(time: str) -> str:
    """Return the time of a log line in UTC (see ``iso_time``), or as is if it is not in a recognized format."""
    try:
        # The daemons log the milliseconds after a comma, which fromisoformat accepts only from Python 3.11.
        return iso_time(datetime.fromisoformat(time.replace(",", ".")))
    except ValueError:
        return time
