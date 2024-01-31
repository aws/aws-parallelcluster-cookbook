#!/usr/bin/env python
"""
Write the CloudWatch agent configuration file.

Write the JSON used to configure the CloudWatch agent on an instance conditional
on the scheduler to be used, the platform (OS family) in use and the instance's role in the cluster.
"""

import argparse
import json
import os
import socket

from cloudwatch_agent_common_utils import render_jinja_template

AWS_CLOUDWATCH_CFG_PATH = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
DEFAULT_METRICS_COLLECTION_INTERVAL = 60


def parse_args():
    """Parse CL args and return an argparse.Namespace."""
    parser = argparse.ArgumentParser(description="Create the cloudwatch agent config file")
    parser.add_argument("--config", help="Path to JSON file describing logs that should be monitored", required=True)
    parser.add_argument(
        "--platform",
        help="OS family of this instance",
        choices=["amazon", "centos", "ubuntu", "redhat", "rocky"],
        required=True,
    )
    parser.add_argument("--log-group", help="Name of the log group", required=True)
    parser.add_argument(
        "--node-role",
        required=True,
        choices=["HeadNode", "ComputeFleet", "LoginNode", "ExternalSlurmDbd"],
        help="Role this node plays in the cluster (i.e., is it a compute node or the head node?)",
    )
    parser.add_argument("--scheduler", required=True, choices=["slurm", "awsbatch"], help="Scheduler")
    return parser.parse_args()


def gethostname():
    """Return hostname of this instance."""
    return socket.gethostname().split(".")[0]


def write_config(config):
    """Write config to AWS_CLOUDWATCH_CFG_PATH."""
    with open(AWS_CLOUDWATCH_CFG_PATH, "w+", encoding="utf-8") as output_config_file:
        json.dump(config, output_config_file, indent=4)


def add_log_group_name_params(log_group_name, configs):
    """Add a "log_group_name": log_group_name to every config."""
    for config in configs:
        config.update({"log_group_name": log_group_name})
    return configs


def add_instance_log_stream_prefixes(configs):
    """Prefix all log_stream_name fields with instance identifiers."""
    for config in configs:
        config["log_stream_name"] = f"{gethostname()}.{{instance_id}}.{config['log_stream_name']}"
    return configs


def read_data(config_path):
    """Read in log configuration data from config_path."""
    with open(config_path, encoding="utf-8") as infile:
        return json.load(infile)


def select_configs_for_scheduler(configs, scheduler):
    """Filter out from configs those entries whose 'schedulers' list does not contain scheduler."""
    return [config for config in configs if scheduler in config["schedulers"]]


def select_configs_for_node_role(configs, node_role):
    """Filter out from configs those entries whose 'node_roles' list does not contain node_role."""
    return [config for config in configs if node_role in config["node_roles"]]


def select_configs_for_platform(configs, platform):
    """Filter out from configs those entries whose 'platforms' list does not contain platform."""
    return [config for config in configs if platform in config["platforms"]]


def get_node_info():
    """Return the information encoded in the JSON file at /etc/chef/dna.json."""
    node_info = {}
    dna_path = "/etc/chef/dna.json"
    if os.path.isfile(dna_path):
        with open(dna_path, encoding="utf-8") as node_info_file:
            node_info = json.load(node_info_file).get("cluster")
    return node_info


def select_configs_for_feature(configs):
    """Filter out from configs those entries whose 'feature_conditions' list contains an unsatisfied entry."""
    selected_configs = []
    node_info = get_node_info()
    for config in configs:
        conditions = config.get("feature_conditions", [])
        for condition in conditions:
            dna_keys = condition.get("dna_key")
            if isinstance(dna_keys, str):  # dna_key can be a string for single level dict or a list for nested dicts
                dna_keys = [dna_keys]
            value = node_info
            for key in dna_keys:
                value = value.get(key)
                if value is None:
                    break
            if value not in condition.get("satisfying_values"):
                break
        else:
            selected_configs.append(config)
    return selected_configs


def select_logs(configs, args):
    """Select the appropriate set of log configs."""
    selected_configs = select_configs_for_scheduler(configs, args.scheduler)
    selected_configs = select_configs_for_node_role(selected_configs, args.node_role)
    selected_configs = select_configs_for_platform(selected_configs, args.platform)
    selected_configs = select_configs_for_feature(selected_configs)
    return selected_configs


def add_timestamps(configs, timestamps_dict):
    """For each config, set its timestamp_format field based on its timestamp_format_key field."""
    for config in configs:
        timestamp_format = timestamps_dict[config["timestamp_format_key"]]
        if timestamp_format:
            config["timestamp_format"] = timestamp_format
    return configs


def filter_output_fields(configs):
    """Remove fields that are not required by CloudWatch agent config file."""
    desired_keys = ["log_stream_name", "file_path", "timestamp_format", "log_group_name"]
    return [
        {desired_key: config[desired_key] for desired_key in desired_keys if desired_key in config}
        for config in configs
    ]


def create_metrics_collected(selected_configs):
    """Create the "metrics_collected" section in metrics configuration for selected metrics."""
    desired_keys = ["measurement", "resources", "metrics_collection_interval"]

    def _collect_metric_properties(metric_config):
        # initial dict with default key-value pairs
        collected = {"metrics_collection_interval": DEFAULT_METRICS_COLLECTION_INTERVAL}
        collected.update({key: metric_config[key] for key in desired_keys if key in metric_config})
        return collected

    return {
        metric_config["metric_type"]: _collect_metric_properties(metric_config) for metric_config in selected_configs
    }


def select_metrics(configs, args):
    """Add metrics_collected for CloudWatch Agent Metrics section."""
    selected_configs = select_configs_for_node_role(configs["metrics_collected"], args.node_role)
    metric_configs = {"metrics_collected": create_metrics_collected(selected_configs)}
    return metric_configs


def select_append_dimensions(dimensions):
    """Create the dictionary of append dimensions according to a list of dimension names."""
    valid_append_dimensions = {
        "ImageID": "${aws:ImageId}",
        "InstanceId": "${aws:InstanceId}",
        "InstanceType": "${aws:InstanceType}",
        "AutoScalingGroupName": "${aws:AutoScalingGroupName}",
    }
    append_dimensions = {key: valid_append_dimensions[key] for key in dimensions}
    return append_dimensions


def add_append_dimensions(metric_configs, configs):
    """Add the "append_dimensions" filed for the CloudWatch Agent Metrics section."""
    if "append_dimensions" in configs and metric_configs["metrics_collected"]:
        metric_configs["append_dimensions"] = select_append_dimensions(configs["append_dimensions"])
    return metric_configs


def add_aggregation_dimensions(metric_configs, configs):
    """Add the "aggregation_dimensions" filed for the CloudWatch Agent Metrics section."""
    if "aggregation_dimensions" in configs and metric_configs["metrics_collected"]:
        metric_configs["aggregation_dimensions"] = configs["aggregation_dimensions"]
    return metric_configs


def create_config(log_configs, metric_configs):
    """Return a dict representing the structure of the output JSON."""
    cw_agent_config = {
        "logs": {
            "logs_collected": {"files": {"collect_list": log_configs}},
            "log_stream_name": f"{gethostname()}.{{instance_id}}.default-log-stream",
        }
    }
    if metric_configs["metrics_collected"]:
        cw_agent_config["metrics"] = metric_configs
    return cw_agent_config


def main():
    """Create cloudwatch agent config file."""
    args = parse_args()
    config_data = read_data(render_jinja_template(args.config))
    log_configs = select_logs(config_data["log_configs"], args)
    log_configs = add_timestamps(log_configs, config_data["timestamp_formats"])
    log_configs = add_log_group_name_params(args.log_group, log_configs)
    log_configs = add_instance_log_stream_prefixes(log_configs)
    log_configs = filter_output_fields(log_configs)
    metric_configs = select_metrics(config_data["metric_configs"], args)
    metric_configs = add_append_dimensions(metric_configs, config_data["metric_configs"])
    metric_configs = add_aggregation_dimensions(metric_configs, config_data["metric_configs"])
    write_config(create_config(log_configs, metric_configs))


if __name__ == "__main__":
    main()
