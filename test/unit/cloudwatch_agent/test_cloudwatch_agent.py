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
from cloudwatch_agent_config_util import validate_json


@pytest.mark.parametrize(
    "error_type",
    [None, "Duplicates", "Schema", "Timestamp"],
)
def test_validate_json(mocker, error_type):
    input_json = {
        "timestamp_formats": {
            "month_first": "%b %-d %H:%M:%S",
        },
        "log_configs": [{"timestamp_format_key": "month_first", "log_stream_name": "test"}],
    }
    if error_type == "Schema":
        input_json = "ERROR"
    elif error_type == "Duplicates":
        input_json["log_configs"].append({"timestamp_format_key": "month_first", "log_stream_name": "test"})
    elif error_type == "Timestamp":
        input_json["log_configs"].append({"timestamp_format_key": "default", "log_stream_name": "test2"})
        print(input_json)
    schema = {"type": "object", "properties": {"timestamp_formats": {"type": "object"}}}
    mocker.patch(
        "cloudwatch_agent_config_util._read_json_at",
        return_value=input_json,
    )
    mocker.patch(
        "cloudwatch_agent_config_util._read_schema",
        return_value=schema,
    )
    try:
        validate_json(input_json)
        validate_json()
        assert_that(error_type).is_none()
    except SystemExit as e:
        if error_type == "Schema":
            assert_that(e.args[0]).contains("Failed validating 'type' in schema")
        elif error_type == "Duplicates":
            assert_that(e.args[0]).contains("The following log_stream_name values are used multiple times: test")
        elif error_type == "Timestamp":
            assert_that(e.args[0]).contains("contains an invalid timestamp_format_key")
