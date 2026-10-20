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

"""Unit tests for the generic dataclass serialization helpers."""

import json
from datetime import datetime, timedelta, timezone

from pcluster_diag.util.serialization import iso_time, log_time, to_dict, to_json
from tests.sample_data import sample_context, sample_result


def test_to_dict_converts_enum_fields_to_their_value():
    context = sample_context()

    data = to_dict(context)

    # Enum fields serialize to their value, not the enum member.
    assert data["node_type"] == context.node_type.value
    assert data["pcluster_version"] == context.pcluster_version
    assert data["pcluster_diag_version"] == context.pcluster_diag_version


def test_to_json_is_deterministic_and_valid_json():
    result = sample_result(check_id="C")

    text = to_json(result)

    # Two serializations of the same object are identical, and the output is valid JSON.
    assert to_json(result) == text
    assert json.loads(text)["status"] == result.status.value


def test_iso_time():
    assert iso_time(datetime(2026, 10, 12, 14, 10, 5, 123456, tzinfo=timezone.utc)) == "2026-10-12T14:10:05+00:00"
    assert iso_time(None) == "unknown"
    # Every time is written in UTC.
    assert iso_time(datetime(2026, 10, 12, 10, 10, 5, tzinfo=timezone(timedelta(hours=-4)))) == (
        "2026-10-12T14:10:05+00:00"
    )


def test_log_time_converts_to_utc_and_keeps_unknown_times():
    assert log_time("2026-10-12T10:02:06-04:00") == "2026-10-12T14:02:06+00:00"
    assert log_time("2026-10-12 14:30:02,118+02:00") == "2026-10-12T12:30:02+00:00"
    assert log_time("not a time") == "not a time"
