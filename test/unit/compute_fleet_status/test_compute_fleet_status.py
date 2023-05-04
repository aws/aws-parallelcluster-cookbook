# Copyright 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
import pytest
from assertpy import assert_that
from compute_fleet_status import get_status_with_last_updated_time, update_status_with_last_updated_time


@pytest.mark.parametrize(
    "no_error",
    [True, False],
)
def test_get_status_with_last_updated_time(no_error, mocker, capsys):
    if no_error:
        mocker.patch(
            "compute_fleet_status.get_dynamo_db_data",
            return_value={"lastStatusUpdatedTime": "2022-01-14T04:40:47.653Z", "status": "PROTECTED"},
        )
    else:
        mocker.patch(
            "compute_fleet_status.get_dynamo_db_data",
            side_effect=Exception("Failed when retrieving data from DynamoDB with error"),
        )

    try:
        get_status_with_last_updated_time("table", "us-east-1")
        readouterr = capsys.readouterr()
        assert_that(readouterr.out).contains(
            '{\n    "lastStatusUpdatedTime": "2022-01-14T04:40:47.653Z",\n    "status": "PROTECTED"\n}\n'
        )
    except Exception as e:
        assert_that(e.args[0]).contains("Failed when retrieving data from DynamoDB with error")


@pytest.mark.parametrize(
    "current_status",
    [
        "PROTECTED",
        "RUNNING",
        "STOPPED",
    ],
)
def test_update_status_with_last_updated_time(current_status, mocker):
    mocker.patch(
        "compute_fleet_status.get_dynamo_db_data",
        return_value={"lastStatusUpdatedTime": "2022-01-14T04:40:47.653Z", "status": current_status},
    )
    update_item_mock = mocker.patch("compute_fleet_status.update_item")

    try:
        update_status_with_last_updated_time("table", "us-east-1", "PROTECTED")
        if current_status == "PROTECTED":
            update_item_mock.assert_not_called()
        else:
            update_item_mock.assert_called_once()
    except Exception as e:
        assert_that(e.args[0]).contains(
            "Failed when updating fleet status with error: Could not update compute fleet status from 'STOPPED' "
            "to PROTECTED."
        )
