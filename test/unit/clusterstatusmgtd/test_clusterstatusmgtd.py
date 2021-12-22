# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
from datetime import datetime, timedelta, timezone

import pytest
from clusterstatusmgtd import _sleep_remaining_loop_time


@pytest.mark.parametrize(
    "loop_start_time, loop_end_time, loop_total_time, expected_sleep_time",
    [
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            60,
            60,
        ),
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 1, 00, tzinfo=timezone.utc),
            60,
            30,
        ),
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 1, 30, tzinfo=timezone.utc),
            60,
            0,
        ),
        (
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            datetime(2020, 1, 1, 0, 0, 0, tzinfo=timezone.utc),
            60,
            0,
        ),
        (
            datetime(2020, 1, 1, 1, 0, 0, tzinfo=timezone(timedelta(hours=1))),
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            60,
            30,
        ),
        (
            datetime(2020, 1, 1, 1, 0, 0),
            datetime(2020, 1, 1, 0, 0, 30, tzinfo=timezone.utc),
            60,
            None,  # can't assert this with naive timezone since the value depends on the system timezone
        ),
    ],
)
def test_sleep_remaining_loop_time(mocker, loop_start_time, loop_end_time, loop_total_time, expected_sleep_time):
    sleep_mock = mocker.patch("time.sleep")
    datetime_now_mock = mocker.MagicMock()
    datetime_now_mock.now = mocker.MagicMock(return_value=loop_end_time, spec=datetime.now)
    mocker.patch("clusterstatusmgtd.datetime", datetime_now_mock)

    _sleep_remaining_loop_time(loop_total_time, loop_start_time)

    if expected_sleep_time:
        sleep_mock.assert_called_with(expected_sleep_time)
    elif expected_sleep_time == 0:
        sleep_mock.assert_not_called()
    datetime_now_mock.now.assert_called_with(tz=timezone.utc)
