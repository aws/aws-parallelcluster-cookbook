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
import os

import pytest
from assertpy import assert_that
from cloudwatch_agent_config_util import validate_json, write_validated_json


@pytest.mark.parametrize(
    "error_type",
    [None, "Duplicates", "Timestamp"],
)
def test_validate_json_content(mocker, error_type):
    input_json = {
        "timestamp_formats": {
            "month_first": "%b %-d %H:%M:%S",
        },
        "log_configs": [{"timestamp_format_key": "month_first", "log_stream_name": "test"}],
    }

    if error_type == "Duplicates":
        input_json["log_configs"].append({"timestamp_format_key": "month_first", "log_stream_name": "test"})
    elif error_type == "Timestamp":
        input_json["log_configs"].append({"timestamp_format_key": "default", "log_stream_name": "test2"})

    schema = {"type": "object", "properties": {"timestamp_formats": {"type": "object"}}}

    mocker.patch(
        "cloudwatch_agent_config_util._read_schema",
        return_value=schema,
    )

    mocker.patch(
        "cloudwatch_agent_config_util._read_log_configs",
        return_value=input_json,
    )

    try:
        validate_json(input_json)
        assert_that(error_type).is_none()
    except SystemExit as e:
        assert_that(error_type).is_not_none()
        if error_type == "Duplicates":
            assert_that(e.args[0]).contains("The following log_stream_name values are used multiple times: test")
        elif error_type == "Timestamp":
            assert_that(e.args[0]).contains("contains an invalid timestamp_format_key")


@pytest.mark.parametrize(
    "error_type",
    [None, "FileNotFound", "Schema"],
)
def test_validate_json_invalid(mocker, error_type):
    input_json = {
        "timestamp_formats": {
            "month_first": "%b %-d %H:%M:%S",
        },
        "log_configs": [{"timestamp_format_key": "month_first", "log_stream_name": "test"}],
    }

    if error_type == "Schema":
        schema = {"type": "string"}
    else:
        schema = {"type": "object", "properties": {"timestamp_formats": {"type": "object"}}}

    mocker.patch(
        "cloudwatch_agent_config_util._read_schema",
        return_value=schema,
    )

    if error_type != "FileNotFound":
        mocker.patch(
            "cloudwatch_agent_config_util._read_log_configs",
            return_value=input_json,
        )

    try:
        validate_json(input_json)
        assert_that(error_type).is_none()
    except SystemExit as e:
        assert_that(error_type).is_not_none()
        if error_type == "FileNotFound":
            assert_that(e.args[0]).contains("No file exists")
        elif error_type == "Schema":
            assert_that(e.args[0]).contains("Failed validating 'type' in schema")


@pytest.mark.parametrize("no_error", [True, False])
def test_validate_json_input(mocker, test_datadir, no_error):
    input_file_path = os.path.join(test_datadir, "config.json")

    schema = {"type": "object", "properties": {"timestamp_formats": {"type": "object"}}}

    mocker.patch(
        "cloudwatch_agent_config_util._read_schema",
        return_value=schema,
    )

    mocker.patch(
        "cloudwatch_agent_config_util._validate_timestamp_keys",
        return_value=None,
    )
    try:
        with open(input_file_path, encoding="utf-8") as input_file:
            if not no_error:
                mocker.patch(
                    "builtins.open",
                    side_effect=ValueError,
                )
            else:
                mocker.patch(
                    "builtins.open",
                    return_value=input_file,
                )
            validate_json()
        assert_that(no_error).is_true()
    except SystemExit as e:
        assert_that(no_error).is_false()
        assert_that(e.args[0]).contains("invalid JSON")


def test_write_validated_json(mocker, test_datadir, tmpdir):
    input_json = {
        "timestamp_formats": {
            "month_first": "%b %-d %H:%M:%S",
        },
        "log_configs": [{"timestamp_format_key": "month_first", "log_stream_name": "test"}],
    }

    input_json2 = {
        "timestamp_formats": {
            "default": "%Y-%m-%d %H:%M:%S,%f",
        },
        "log_configs": [{"timestamp_format_key": "month_first", "log_stream_name": "test2"}],
    }

    output_file = f"{tmpdir}/output.json"

    mocker.patch(
        "cloudwatch_agent_config_util._read_json_at",
        return_value=input_json,
    )

    mocker.patch("os.environ.get", return_value=output_file)

    write_validated_json(input_json2)

    expected = os.path.join(test_datadir, "output.json")

    with open(output_file, encoding="utf-8") as f, open(expected, encoding="utf-8") as exp_f:
        assert_that(f.read()).is_equal_to(exp_f.read())
