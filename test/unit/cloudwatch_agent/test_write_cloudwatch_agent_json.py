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
from write_cloudwatch_agent_json import (
    add_aggregation_dimensions,
    add_append_dimensions,
    add_instance_log_stream_prefixes,
    add_log_group_name_params,
    add_timestamps,
    create_config,
    filter_output_fields,
    select_configs_for_feature,
    select_configs_for_node_role,
    select_configs_for_platform,
    select_configs_for_scheduler,
    select_metrics,
)

CONFIGS = [
    {
        "timestamp_format_key": "month_first",
        "file_path": "/var/log/messages",
        "log_stream_name": "system-messages",
        "schedulers": ["awsbatch", "slurm"],
        "node_roles": ["ComputeFleet", "HeadNode"],
        "platforms": ["amazon", "centos"],
        "feature_conditions": [{"dna_key": "dcv_enabled", "satisfying_values": ["head_node"]}],
    },
    {
        "timestamp_format_key": "month_first",
        "file_path": "/var/log/syslog",
        "log_stream_name": "syslog",
        "log_group_name": "pre-existing",
        "schedulers": ["awsbatch", "slurm"],
        "node_roles": ["ComputeFleet", "HeadNode"],
        "platforms": ["ubuntu"],
        "feature_conditions": [{"dna_key": ["directory_service", "enabled"], "satisfying_values": ["true"]}],
    },
    {
        "timestamp_format_key": "default",
        "file_path": "/var/log/cfn-init.log",
        "log_stream_name": "cfn-init",
        "schedulers": ["awsbatch"],
        "node_roles": ["HeadNode"],
        "platforms": ["amazon", "centos", "ubuntu"],
        "feature_conditions": [],
    },
]

METRIC_CONFIGS = {
    "metrics_collected": [
        {
            "metric_type": "mem",
            "measurement": ["mem_used_percent"],
            "metrics_collection_interval": 60,
            "node_roles": ["HeadNode"],
        },
        {
            "metric_type": "disk",
            "measurement": ["disk_used_percent"],
            "resources": ["/"],
            "metrics_collection_interval": 60,
            "node_roles": ["HeadNode"],
        },
    ],
    "append_dimensions": ["InstanceId"],
    "aggregation_dimensions": [["InstanceId", "path"]],
}


@pytest.mark.asyncio
def test_add_log_group_name_params():
    configs = add_log_group_name_params("test", CONFIGS)
    for config in configs:
        assert_that(config).contains("log_group_name")
        assert_that(config["log_group_name"]).is_equal_to("test")


@pytest.mark.asyncio
def test_add_instance_log_stream_prefixes(mocker):
    instance_id = "i-0096test"
    mocker.patch(
        "write_cloudwatch_agent_json.gethostname",
        return_value=instance_id,
    )

    configs = add_instance_log_stream_prefixes(CONFIGS)
    for config in configs:
        assert_that(config["log_stream_name"]).contains(instance_id)


@pytest.mark.asyncio
def test_select_configs_for_scheduler():
    configs = select_configs_for_scheduler(CONFIGS, "slurm")
    assert_that(len(configs)).is_equal_to(2)
    configs = select_configs_for_scheduler(CONFIGS, "awsbatch")
    assert_that(len(configs)).is_equal_to(3)


@pytest.mark.asyncio
def test_select_configs_for_node_role():
    configs = select_configs_for_node_role(CONFIGS, "ComputeFleet")
    assert_that(len(configs)).is_equal_to(2)
    configs = select_configs_for_node_role(CONFIGS, "HeadNode")
    assert_that(len(configs)).is_equal_to(3)


@pytest.mark.asyncio
def test_select_configs_for_platform():
    configs = select_configs_for_platform(CONFIGS, "amazon")
    assert_that(len(configs)).is_equal_to(2)
    configs = select_configs_for_platform(CONFIGS, "ubuntu")
    assert_that(len(configs)).is_equal_to(2)


@pytest.mark.parametrize(
    "info",
    [
        {"node_info": {"dcv_enabled": "head_node", "directory_service": {"enabled": "true"}}, "length": 3},
        {"node_info": {"directory_service": {"enabled": "true"}}, "length": 2},
        {"node_info": {"enabled": "true"}, "length": 1},
    ],
)
def test_select_configs_for_feature(mocker, info):
    node_info = info["node_info"]
    mocker.patch(
        "write_cloudwatch_agent_json.get_node_info",
        return_value=node_info,
    )
    selected_configs = select_configs_for_feature(CONFIGS)
    assert_that(len(selected_configs)).is_equal_to(info["length"])


@pytest.mark.asyncio
def test_add_timestamps():
    timestamp_formats = {"month_first": "%b %-d %H:%M:%S", "default": "%Y-%m-%d %H:%M:%S,%f"}
    configs = add_timestamps(CONFIGS, timestamp_formats)
    for config in configs:
        timestamp_format = timestamp_formats[config["timestamp_format_key"]]
        assert_that(config["timestamp_format"]).is_equal_to(timestamp_format)


@pytest.mark.asyncio
def test_filter_output_fields():
    desired_keys = ["log_stream_name", "file_path", "timestamp_format", "log_group_name"]
    configs = filter_output_fields(CONFIGS)
    for config in configs:
        for key in config:
            assert_that(desired_keys).contains(key)


@pytest.mark.asyncio
def test_create_config(mocker):
    instance_id = "i-0096test"
    mocker.patch(
        "write_cloudwatch_agent_json.gethostname",
        return_value=instance_id,
    )

    cw_agent_config = create_config(CONFIGS, METRIC_CONFIGS)

    assert_that(len(cw_agent_config)).is_equal_to(2)
    assert_that(len(cw_agent_config["logs"]["logs_collected"]["files"]["collect_list"])).is_equal_to(3)
    assert_that(cw_agent_config["logs"]["log_stream_name"]).contains(instance_id)


@pytest.mark.asyncio
def test_select_metrics(mocker):
    mocker.patch(
        "write_cloudwatch_agent_json.select_configs_for_node_role",
        return_value=METRIC_CONFIGS["metrics_collected"],
    )

    metric_configs = select_metrics(METRIC_CONFIGS, mocker.MagicMock())
    assert_that(len(metric_configs)).is_equal_to(1)
    assert_that(metric_configs["metrics_collected"]).is_type_of(dict)
    for key in metric_configs["metrics_collected"]:
        assert_that(metric_configs["metrics_collected"][key]).does_not_contain_key("node_roles")


@pytest.mark.asyncio
def test_add_append_dimensions():
    metrics = {"metrics_collected": METRIC_CONFIGS["metrics_collected"]}
    metrics = add_append_dimensions(metrics, METRIC_CONFIGS)

    assert_that(len(metrics)).is_equal_to(2)
    assert_that(metrics["append_dimensions"]).is_type_of(dict)
    assert_that(metrics["append_dimensions"]).contains_key("InstanceId")


@pytest.mark.asyncio
def test_add_aggregation_dimensions():
    metrics = {"metrics_collected": METRIC_CONFIGS["metrics_collected"]}
    metrics = add_aggregation_dimensions(metrics, METRIC_CONFIGS)

    assert_that(len(metrics)).is_equal_to(2)
    assert_that(len(metrics["aggregation_dimensions"])).is_equal_to(1)
    assert_that(metrics["aggregation_dimensions"][0]).is_type_of(list)
    assert_that(metrics["aggregation_dimensions"][0]).contains("InstanceId")
    assert_that(metrics["aggregation_dimensions"][0]).contains("path")
