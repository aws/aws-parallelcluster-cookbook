# Copyright 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
import json
import os
import subprocess  # nosec B404
import tempfile
from types import SimpleNamespace
from unittest.mock import MagicMock, call

import botocore
import pytest
from assertpy import assert_that
from custom_action_executor import (
    SCRIPT_LOG_NAME_FETCH_AND_RUN,
    ActionRunner,
    ComputeFleetLogger,
    ConfigLoader,
    DownloadRunError,
    ExecutableScript,
    HeadNodeLogger,
    LegacyEventName,
    ScriptDefinition,
    ScriptRunner,
    main,
)
from mock.mock import AsyncMock

# pylint: disable=redefined-outer-name
# pylint: disable=protected-access


@pytest.fixture
def script_runner():
    return ScriptRunner("OnMockTestEvent")


@pytest.fixture
def s3_script():
    return ScriptDefinition(url="s3://bucket/script.sh", args=["arg1", "arg2"])


@pytest.fixture
def http_script():
    return ScriptDefinition(url="http://example.com/script.sh", args=["arg1", "arg2"])


@pytest.fixture
def https_script():
    return ScriptDefinition(url="https://example.com/script.sh", args=["arg1", "arg2"])


def test_is_s3_url(script_runner):
    assert_that(script_runner._is_s3_url("s3://bucket/script.sh")).is_true()
    assert_that(script_runner._is_s3_url("http://example.com/script.sh")).is_false()


def test_parse_s3_url(script_runner):
    assert_that(script_runner._parse_s3_url("s3://bucket/script.sh")).is_equal_to(("bucket", "script.sh"))
    assert_that(script_runner._parse_s3_url("s3://bucket/dir/script.sh")).is_equal_to(("bucket", "dir/script.sh"))
    assert_that(script_runner._parse_s3_url("s3://bucket/path/to/script.sh")).is_equal_to(
        ("bucket", "path/to/script.sh")
    )


def write_to_file(filename, file_contents: bytes):
    with open(filename, "w", encoding="utf-8") as file:
        file.write(file_contents.decode())


@pytest.mark.asyncio
async def test_download_s3_script(script_runner, s3_script, mocker):
    #  Mock the s3 download of file_contents via s3 resource mocking
    file_contents: bytes = b"#!/bin/bash\n"
    mock_resource = MagicMock()
    mock_resource.download_file = MagicMock(side_effect=(lambda key, filename: write_to_file(filename, file_contents)))

    mocker.patch("boto3.resource").return_value.Bucket.return_value = mock_resource

    # Act
    exe_script = await script_runner._download_script(s3_script)
    downloaded_file_path = exe_script.path

    # Assert
    assert_that(downloaded_file_path).is_not_equal_to(s3_script.url)
    with open(downloaded_file_path, encoding="utf-8") as downloaded_file:
        assert_that(downloaded_file.read()).is_equal_to("#!/bin/bash\n")


@pytest.mark.asyncio
async def test_download_https_script(script_runner, https_script, mocker):
    response_mock = MagicMock()
    response_mock.status_code = 200
    content = b"#!/bin/bash\n"
    response_mock.content = content
    mocker.patch("requests.get", return_value=response_mock)

    result: ExecutableScript = await script_runner._download_script(https_script)

    assert_that(result.path).is_instance_of(str)
    with open(result.path, encoding="utf-8") as f:
        assert_that(f.read()).is_equal_to("#!/bin/bash\n")


@pytest.mark.asyncio
async def test_download_http_script_not_allowed(script_runner, http_script):
    with pytest.raises(
        DownloadRunError,
        match="Failed to download OnMockTestEvent script 0 http://example.com/script.sh, "
        "URL must be an s3 or HTTPs.",
    ):
        await script_runner._download_script(http_script)


@pytest.mark.asyncio
async def test_download_s3_script_error(script_runner, mocker, s3_script):
    mock_resource = MagicMock()
    mock_resource.download_file = MagicMock(
        side_effect=botocore.exceptions.ClientError({"Error": {"Code": 403}}, "test error")
    )
    mocker.patch("boto3.resource").return_value.Bucket.return_value = mock_resource

    with pytest.raises(
        DownloadRunError,
        match="Failed to download OnMockTestEvent script 0 s3://bucket/script.sh "
        r"using aws s3, cause: An error occurred \(403\).*",
    ):
        await script_runner._download_script(s3_script)


@pytest.mark.asyncio
async def test_download_https_script_error(script_runner, mocker, https_script):
    response_mock = MagicMock()
    response_mock.status_code = 403
    response_mock.content = b"test error"
    mocker.patch("requests.get", return_value=response_mock)

    with pytest.raises(
        DownloadRunError,
        match="Failed to download OnMockTestEvent script 0 " "https://example.com/script.sh, HTTP status code 403",
    ):
        await script_runner._download_script(https_script)


def build_exe_script(args=None):
    return ExecutableScript(url="s3://bucket/script.sh", step_num=0, path="/this/is/a/path/to/script.sh", args=args)


@pytest.mark.parametrize("args", [None, [], ["arg1", "arg2"], ["arg1", "arg2", "arg3"]])
@pytest.mark.asyncio
async def test_execute_script(script_runner, mocker, args):
    # mock process execution
    process_mock = MagicMock()
    process_mock.returncode = 0
    subprocess_mock = mocker.patch("subprocess.run", return_value=process_mock)

    exe_script = build_exe_script(args)
    await script_runner._execute_script(exe_script)

    # assert that subprocess_mock is called twice
    subprocess_mock.assert_has_calls(
        [
            call(["chmod", "+x", exe_script.path], check=True, stderr=subprocess.PIPE),
            call([exe_script.path] + (exe_script.args or []), check=True, stderr=subprocess.PIPE),
        ]
    )


@pytest.mark.asyncio
async def test_execute_script_error_not_executable(script_runner):
    with pytest.raises(
        DownloadRunError,
        match="Failed to run OnMockTestEvent script 0 s3://bucket/script.sh due "
        "to a failure in making the file executable, return code: 1.",
    ):
        await script_runner._execute_script(build_exe_script())


@pytest.mark.asyncio
async def test_execute_script_error_in_execution(script_runner, mocker):
    # mock process execution
    process_mock = MagicMock()
    process_mock.returncode = 0
    # patch subprocess.run: first call succeeds, second call fails with non-zero return code
    mocker.patch("subprocess.run", side_effect=[process_mock, subprocess.CalledProcessError(1, "test error")])

    with pytest.raises(
        DownloadRunError,
        match="Failed to execute OnMockTestEvent script 0 s3://bucket/script.sh, " "return code: 1.",
    ):
        await script_runner._execute_script(build_exe_script())


def create_persistent_tmp_file(additional_content: str = "") -> str:
    with tempfile.NamedTemporaryFile(delete=False) as f:
        f.write(b"#!/bin/bash\n")
        f.write(additional_content.encode())
        return f.name


@pytest.mark.asyncio
async def test_download_and_execute_scripts(script_runner, mocker, s3_script, https_script):
    tmp_file1 = create_persistent_tmp_file()
    tmp_file2 = create_persistent_tmp_file()

    exe_script1 = script_runner._build_exe_script(s3_script, 1, tmp_file1)
    exe_script2 = script_runner._build_exe_script(https_script, 2, tmp_file2)

    download_script_mock = AsyncMock(side_effect=[exe_script1, exe_script2])
    mocker.patch.object(script_runner, "_download_script", download_script_mock)
    execute_script_mock = AsyncMock()
    mocker.patch.object(script_runner, "_execute_script", execute_script_mock)
    unlink_mock = MagicMock()
    mocker.patch.object(os, "unlink", unlink_mock)

    await script_runner.download_and_execute_scripts([s3_script, https_script])

    assert_that(unlink_mock.call_count).is_equal_to(2)

    assert_that(execute_script_mock.await_count).is_equal_to(2)
    execute_script_mock.assert_has_awaits([call(exe_script1), call(exe_script2)])

    mocker.stopall()
    os.unlink(tmp_file1)
    os.unlink(tmp_file2)


@pytest.mark.parametrize(
    "legacy_event_name",
    [LegacyEventName.ON_NODE_START, LegacyEventName.ON_NODE_CONFIGURED, LegacyEventName.ON_NODE_UPDATED],
)
@pytest.mark.asyncio
async def test_action_runner_run_event(mocker, legacy_event_name, https_script):
    conf_mock = MagicMock()
    conf_mock.legacy_event = legacy_event_name
    conf_mock.can_execute = True
    conf_mock.dry_run = False
    script_sequence = [https_script, https_script]
    conf_mock.script_sequence = script_sequence

    download_and_execute_scripts_mock = AsyncMock()
    mocker.patch(
        "custom_action_executor.ScriptRunner.download_and_execute_scripts",
        side_effect=download_and_execute_scripts_mock,
    )
    mocker.patch("custom_action_executor.ActionRunner._get_stack_status", return_value="UPDATE_IN_PROGRESS")
    asyncio_run_mock = mocker.patch("asyncio.run")

    ActionRunner(conf_mock, MagicMock()).run()

    await asyncio_run_mock.call_args[0][0]

    download_and_execute_scripts_mock.assert_awaited_once_with(script_sequence)


def test_action_runner_run_on_node_updated_stack_not_in_progress(mocker, https_script):
    conf_mock = MagicMock()
    conf_mock.legacy_event = LegacyEventName.ON_NODE_UPDATED
    conf_mock.can_execute = True
    script_sequence = [https_script, https_script]
    conf_mock.script_sequence = script_sequence

    script_runner_mock = mocker.patch("custom_action_executor.ScriptRunner.download_and_execute_scripts")
    mocker.patch("custom_action_executor.ActionRunner._get_stack_status", return_value="UPDATE_COMPLETE")

    mock_print = mocker.patch("builtins.print")

    ActionRunner(conf_mock, MagicMock()).run()

    mock_print.assert_called_once_with("Post update hook called with CFN stack in state UPDATE_COMPLETE, doing nothing")
    script_runner_mock.assert_not_called()


def test_log_without_url(mocker):
    mock_conf = MagicMock()
    mock_conf.dry_run = True

    process_mock = MagicMock()
    process_mock.returncode = 0

    mock_print = mocker.patch("builtins.print")

    with pytest.raises(SystemExit) as err:
        HeadNodeLogger(mock_conf).error_exit_with_bootstrap_error("test message", "test_url")

    assert_that(err.value.code).is_equal_to(1)
    assert_that(mock_print.call_count).is_equal_to(2)
    assert_that(mock_print.call_args_list[0][0][0]).matches(r".*test message.*")
    assert_that(mock_print.call_args_list[1][0][0]).matches(r"Would write to .* test_url.*")


@pytest.mark.parametrize(
    "args, conf_file_content, scripts_sequence",
    [
        (
            {
                LegacyEventName.ON_NODE_START.value: True,
                "node_type": "HeadNode",
            },
            {
                "HeadNode": {
                    "CustomActions": {
                        "OnNodeStart": {"Script": "https://example.com/script.sh", "Args": ["arg1", "arg2"]}
                    }
                }
            },
            [ScriptDefinition(url="https://example.com/script.sh", args=["arg1", "arg2"])],
        ),
        (
            {
                LegacyEventName.ON_NODE_START.value: True,
                "node_type": "NotReallyAHeadNode",
                "queue_name": "happyqueue1",
            },
            {
                "Scheduling": {
                    "SlurmQueues": [
                        {
                            "CustomActions": {
                                "OnNodeStart": {"Script": "https://example.com/script.sh", "Args": ["arg1", "arg2"]}
                            },
                            "Name": "happyqueue1",
                        }
                    ]
                }
            },
            [ScriptDefinition(url="https://example.com/script.sh", args=["arg1", "arg2"])],
        ),
        (
            {
                LegacyEventName.ON_NODE_CONFIGURED.value: True,
                "node_type": "NotReallyAHeadNode",
                "queue_name": "happyqueue2",
            },
            {
                "Scheduling": {
                    "Wathever": [
                        {
                            "CustomActions": {
                                "OnNodeConfigure": {"Script": "https://example.com/script.sh", "Args": ["arg1", "arg2"]}
                            },
                            "Name": "happyqueue1",
                        },
                        {
                            "CustomActions": {
                                "OnNodeConfigured": {
                                    "Script": "https://example.com/happy2/script.sh",
                                    "Args": ["arg1", "arg2"],
                                }
                            },
                            "Name": "happyqueue2",
                        },
                    ]
                }
            },
            [ScriptDefinition(url="https://example.com/happy2/script.sh", args=["arg1", "arg2"])],
        ),
        (
            {
                LegacyEventName.ON_NODE_UPDATED.value: True,
                "node_type": "HeadNode",
            },
            {
                "HeadNode": {
                    "CustomActions": {
                        "OnNodeUpdated": {
                            "Sequence": [
                                {"Script": "https://example.com/script1.sh", "Args": ["arg1", "arg2"]},
                                {"Script": "https://example.com/script2.sh", "Args": ["arg1", "arg2", "args3"]},
                            ]
                        }
                    }
                }
            },
            [
                ScriptDefinition(url="https://example.com/script1.sh", args=["arg1", "arg2"]),
                ScriptDefinition(url="https://example.com/script2.sh", args=["arg1", "arg2", "args3"]),
            ],
        ),
    ],
)
def test_config_loader(mocker, args, conf_file_content, scripts_sequence):
    mocker.patch("custom_action_executor.ConfigLoader._load_cluster_config", return_value=conf_file_content)

    for legacy_name in LegacyEventName:
        if legacy_name.value not in args:
            args[legacy_name.value] = False
    mock_args = MagicMock(**args)

    conf = ConfigLoader().load_configuration(mock_args)

    assert_that(conf.script_sequence).contains_sequence(*scripts_sequence)


def test_config_loader_config_file_not_found():
    with pytest.raises(FileNotFoundError) as err:
        ConfigLoader().load_configuration(MagicMock(cluster_configuration="not_found.yaml"))
    assert_that(err.value.filename).is_equal_to("not_found.yaml")


@pytest.mark.parametrize("args", [[], ["error"], ["-h"], ["-v", "-e", "postinstall"]])
def test_main_execution_with_arguments(mocker, args):
    mocker.patch("sys.argv", [SCRIPT_LOG_NAME_FETCH_AND_RUN, *args])

    with pytest.raises(SystemExit) as err:
        main()

    assert_that(err.value.code).is_equal_to(1)


@pytest.mark.parametrize(
    "node_name, action, expected_event",
    [
        (
            None,
            "OnNodeStart",
            {
                "datetime": r".*",
                "version": 0,
                "scheduler": "slurm",
                "cluster-name": "integ-tests-j3v1lgb0rx4uvt5y",
                "node-role": "ComputeFleet",
                "component": "custom-action",
                "level": "ERROR",
                "instance-id": "i-instance",
                "compute": {
                    "name": "unknown",
                    "instance-id": "i-instance",
                    "instance-type": "c5.xlarge",
                    "availability-zone": "us-east-1c",
                    "address": "127.0.0.1",
                    "hostname": "my_immortal",
                    "queue-name": "partition-1",
                    "compute-resource": "compute-a",
                    "node-type": "unknown",
                },
                "event-type": "custom-action-error",
                "message": "hello",
                "detail": {"action": "OnNodeStart", "step": 1, "stage": "executing", "error": {"a": 1, "b": "error"}},
            },
        ),
        (
            "fancy_biscuit",
            "OnNodeStart",
            {
                "datetime": r".*",
                "version": 0,
                "scheduler": "slurm",
                "cluster-name": "integ-tests-j3v1lgb0rx4uvt5y",
                "node-role": "ComputeFleet",
                "component": "custom-action",
                "level": "ERROR",
                "instance-id": "i-instance",
                "compute": {
                    "name": "fancy_biscuit",
                    "instance-id": "i-instance",
                    "instance-type": "c5.xlarge",
                    "availability-zone": "us-east-1c",
                    "address": "127.0.0.1",
                    "hostname": "my_immortal",
                    "queue-name": "partition-1",
                    "compute-resource": "compute-a",
                    "node-type": "unknown",
                },
                "event-type": "custom-action-error",
                "message": "hello",
                "detail": {"action": "OnNodeStart", "step": 1, "stage": "executing", "error": {"a": 1, "b": "error"}},
            },
        ),
        (
            "a-very-static-st-node-1",
            "OnNodeStart",
            {
                "datetime": r".*",
                "version": 0,
                "scheduler": "slurm",
                "cluster-name": "integ-tests-j3v1lgb0rx4uvt5y",
                "node-role": "ComputeFleet",
                "component": "custom-action",
                "level": "ERROR",
                "instance-id": "i-instance",
                "compute": {
                    "name": "a-very-static-st-node-1",
                    "instance-id": "i-instance",
                    "instance-type": "c5.xlarge",
                    "availability-zone": "us-east-1c",
                    "address": "127.0.0.1",
                    "hostname": "my_immortal",
                    "queue-name": "partition-1",
                    "compute-resource": "compute-a",
                    "node-type": "static",
                },
                "event-type": "custom-action-error",
                "message": "hello",
                "detail": {"action": "OnNodeStart", "step": 1, "stage": "executing", "error": {"a": 1, "b": "error"}},
            },
        ),
        (
            "an-action-oriented-dy-node-2",
            "OnNodeConfigured",
            {
                "datetime": r".*",
                "version": 0,
                "scheduler": "slurm",
                "cluster-name": "integ-tests-j3v1lgb0rx4uvt5y",
                "node-role": "ComputeFleet",
                "component": "custom-action",
                "level": "ERROR",
                "instance-id": "i-instance",
                "compute": {
                    "name": "an-action-oriented-dy-node-2",
                    "instance-id": "i-instance",
                    "instance-type": "c5.xlarge",
                    "availability-zone": "us-east-1c",
                    "address": "127.0.0.1",
                    "hostname": "my_immortal",
                    "queue-name": "partition-1",
                    "compute-resource": "compute-a",
                    "node-type": "dynamic",
                },
                "event-type": "custom-action-error",
                "message": "hello",
                "detail": {
                    "action": "OnNodeConfigured",
                    "step": 1,
                    "stage": "executing",
                    "error": {"a": 1, "b": "error"},
                },
            },
        ),
    ],
)
def test_compute_fleet_logger(mocker, node_name, action, expected_event):
    config = SimpleNamespace(
        event_name=action,
        stack_name="integ-tests-j3v1lgb0rx4uvt5y-ComputeFleetQueueBatch0QueueGroup0NestedStackQueueGroup0N"
        "-VC66PPA3U8IR",
        node_type="ComputeFleet",
        instance_id="i-instance",
        instance_type="c5.xlarge",
        availability_zone="us-east-1c",
        ip_address="127.0.0.1",
        hostname="my_immortal",
        queue_name="partition-1",
        resource_name="compute-a",
        node_spec_file="/opt/parallelcluster/slurm_nodename",
        dry_run=False,
    )

    def name_reader(*args, **kwargs):
        if node_name:
            return node_name
        raise ValueError()

    def write_handler(**kwargs):
        received_events.append(kwargs.get("message"))

    received_events = []

    ComputeFleetLogger._read_node_name = name_reader

    fleet_logger = ComputeFleetLogger(config)
    fleet_logger._write_bootstrap_error = write_handler
    error_exit_mock = mocker.patch("custom_action_executor.CustomLogger.error_exit")
    sleep_mock = mocker.patch("time.sleep")
    fleet_logger.error_exit_with_bootstrap_error(
        "hello url", "hello", step=1, stage="executing", error={"a": 1, "b": "error"}
    )

    assert_that(received_events).is_length(1)
    actual_event = json.loads(received_events[0])

    assert_that(actual_event).is_equal_to(expected_event, ignore="datetime")

    error_exit_mock.assert_called_once_with("hello url")
    sleep_mock.assert_called_once_with(5)


@pytest.mark.parametrize(
    "stack_name, expected_cluster_name",
    [
        ("", ""),
        ("not-a-child-stack", "not-a-child-stack"),
        (
            "integ-tests-j3v1lgb0rx4uvt5y-ComputeFleetQueueBatch0QueueGroup0NestedStackQueueGroup0N-VC66PPA3U8IR",
            "integ-tests-j3v1lgb0rx4uvt5y",
        ),
        (
            "integ-tests-j3v1lgb0rx4uvt5y-ComputeFleetQueueBatch332QueueGroup773NestedStackQueueGroup441N-VC66PPA3U8IR",
            "integ-tests-j3v1lgb0rx4uvt5y",
        ),
        (
            "integ-tests-j3v1lgb0rx4uvt5y-ComputeFleetQueueBatch0QueueGroup0NestedStackQueueGroup0N-VC66PPA3U8IR-"
            + "ComputeFleetQueueBatch0QueueGroup0NestedStackQueueGroup0N-VC66PPA3U8IR",
            "integ-tests-j3v1lgb0rx4uvt5y-ComputeFleetQueueBatch0QueueGroup0NestedStackQueueGroup0N-VC66PPA3U8IR",
        ),
    ],
    ids=[
        "empty string",
        "does not match pattern",
        "matches pattern",
        "matches pattern with larger numbers",
        "repeated matching suffix strips last matching suffix",
    ],
)
def test_cluster_name_parsing(stack_name, expected_cluster_name):
    config = SimpleNamespace(
        event_name="action",
        stack_name=stack_name,
        node_type="ComputeFleet",
        instance_id="i-instance",
        instance_type="c5.xlarge",
        availability_zone="us-east-1c",
        ip_address="127.0.0.1",
        hostname="my_immortal",
        queue_name="partition-1",
        resource_name="compute-a",
        node_spec_file="/opt/parallelcluster/slurm_nodename",
        dry_run=False,
    )
    fleet_logger = ComputeFleetLogger(config)

    assert_that(fleet_logger._get_cluster_name()).is_equal_to(expected_cluster_name)
