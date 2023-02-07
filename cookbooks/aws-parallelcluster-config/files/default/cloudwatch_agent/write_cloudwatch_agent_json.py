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

import yaml

AWS_CLOUDWATCH_CFG_PATH = "/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json"
DEFAULT_METRICS_COLLECTION_INTERVAL = 60


def parse_args():
    """Parse CL args and return an argparse.Namespace."""
    parser = argparse.ArgumentParser(description="Create the cloudwatch agent config file")
    parser.add_argument("--config", help="Path to JSON file describing logs that should be monitored", required=True)
    parser.add_argument(
        "--platform", help="OS family of this instance", choices=["amazon", "centos", "ubuntu", "redhat"], required=True
    )
    parser.add_argument("--log-group", help="Name of the log group", required=True)
    parser.add_argument(
        "--node-role",
        required=True,
        choices=["HeadNode", "ComputeFleet"],
        help="Role this node plays in the cluster " "(i.e., is it a compute node or the head node?)",
    )
    parser.add_argument("--scheduler", required=True, choices=["slurm", "awsbatch", "plugin"], help="Scheduler")
    parser.add_argument(
        "--cluster-config-path",
        required=False,
        help="Cluster configuration path",
    )
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


def get_node_roles(scheudler_plugin_node_roles):
    node_type_roles_map = {"ALL": ["ComputeFleet", "HeadNode"], "HEAD": ["HeadNode"], "COMPUTE": ["ComputeFleet"]}
    return node_type_roles_map.get(scheudler_plugin_node_roles)


def load_config(cluster_config_path):
    with open(cluster_config_path, encoding="utf-8") as input_file:
        return yaml.load(input_file, Loader=yaml.SafeLoader)


def add_scheduler_plugin_log(config_data, cluster_config_path):
    """Add custom log files to config data if log files specified in scheduler plugin."""
    cluster_config = load_config(cluster_config_path)
    if (
            get_dict_value(cluster_config, "Scheduling.SchedulerSettings.SchedulerDefinition.Monitoring.Logs.Files")
            and get_dict_value(cluster_config, "Scheduling.Scheduler") == "plugin"
    ):
        log_files = get_dict_value(
            cluster_config, "Scheduling.SchedulerSettings.SchedulerDefinition.Monitoring.Logs.Files"
        )
        for log_file in log_files:
            # Add log config
            log_config = {
                "timestamp_format_key": log_file.get("LogStreamName"),
                "file_path": log_file.get("FilePath"),
                "log_stream_name": log_file.get("LogStreamName"),
                "schedulers": ["plugin"],
                "platforms": ["centos", "ubuntu", "amazon", "redhat"],
                "node_roles": get_node_roles(log_file.get("NodeType")),
                "feature_conditions": [],
            }
            config_data["log_configs"].append(log_config)

            # Add timestamp formats
            config_data["timestamp_formats"][log_file.get("LogStreamName")] = log_file.get("TimestampFormat")
    return config_data


def add_timestamps(configs, timestamps_dict):
    """For each config, set its timestamp_format field based on its timestamp_format_key field."""
    for config in configs:
        config["timestamp_format"] = timestamps_dict[config["timestamp_format_key"]]
    return configs


def filter_output_fields(configs):
    """Remove fields that are not required by CloudWatch agent config file."""
    desired_keys = ["log_stream_name", "file_path", "timestamp_format", "log_group_name"]
    return [{desired_key: config[desired_key] for desired_key in desired_keys} for config in configs]


def select_metrics(args):
    """Add metrics_collected for CloudWatch Agent Metrics section."""
    metric_configs = {}
    metrics_collected = {}
    metrics_collected = add_metrics_mem(metrics_collected, args.node_role)
    metrics_collected = add_metrics_disk(metrics_collected, args.node_role)
    metric_configs['metrics_collected'] = metrics_collected
    return metric_configs


def add_metrics_mem(metrics_collected, node_role):
    """Add memory metrics for the metrics_collected field of CloudWatch Agent Metrics section."""
    if node_role == "HeadNode":
        metrics_collected['mem'] = {
            "measurement": [
                "mem_used_percent"
            ],
            "metrics_collection_interval": DEFAULT_METRICS_COLLECTION_INTERVAL,
            "append_dimensions": {'ClusterName': get_node_info().get('stack_name')}
        }
    return metrics_collected


def add_metrics_disk(metrics_collected, node_role):
    """Add disk metrics for the metrics_collected field of CloudWatch Agent Metrics section."""
    if node_role == "HeadNode":
        metrics_collected['disk'] = {
            "measurement": [
                "disk_used_percent"
            ],
            "metrics_collection_interval": DEFAULT_METRICS_COLLECTION_INTERVAL,
            "resources": [
                "/"
            ],
            "append_dimensions": {'ClusterName': get_node_info().get('stack_name')}
        }
    return metrics_collected


def add_append_dimensions(metric_configs):
    """Add the "append_dimensions" filed for the CloudWatch Agent Metrics section."""
    append_dimensions = {"InstanceId": "${aws:InstanceId}"}
    if len(metric_configs['metrics_collected']) > 0:
        metric_configs['append_dimensions'] = append_dimensions
    return metric_configs

def add_aggregation_dimensions(metric_configs):
    """Add the "aggregation_dimensions" filed for the CloudWatch Agent Metrics section."""
    aggregation_dimensions = [
        ['ClusterName'],
        ['InstanceId']
    ]
    if len(metric_configs['metrics_collected']) > 0:
        metric_configs['aggregation_dimensions'] = aggregation_dimensions
    return metric_configs


def create_config(log_configs, metric_configs):
    """Return a dict representing the structure of the output JSON."""
    logs_section = {
        "logs_collected": {"files": {"collect_list": log_configs}},
        "log_stream_name": f"{gethostname()}.{{instance_id}}.default-log-stream",
    }
    metrics_section = {
        "metrics_collected": metric_configs['metrics_collected'],
        "append_dimensions": metric_configs['append_dimensions'],
        "aggregation_dimensions": metric_configs['aggregation_dimensions']
    } if len(metric_configs['metrics_collected']) > 0 else {}
    cw_agent_config = {"logs": logs_section}
    if len(metrics_section) > 0:
        cw_agent_config["metrics"] = metrics_section
    return cw_agent_config


def get_dict_value(value, attributes, default=None):
    """Get key value from dictionary and return default if the key does not exist."""
    for key in attributes.split("."):
        value = value.get(key, None)
        if value is None:
            return default
    return value


def main():
    """Create cloudwatch agent config file."""
    args = parse_args()
    config_data = read_data(args.config)
    if args.cluster_config_path:
        config_data = add_scheduler_plugin_log(config_data, args.cluster_config_path)
    log_configs = select_logs(config_data["log_configs"], args)
    log_configs = add_timestamps(log_configs, config_data["timestamp_formats"])
    log_configs = add_log_group_name_params(args.log_group, log_configs)
    log_configs = add_instance_log_stream_prefixes(log_configs)
    log_configs = filter_output_fields(log_configs)
    metric_configs = select_metrics(args)
    metric_configs = add_append_dimensions(metric_configs)
    metric_configs = add_aggregation_dimensions(metric_configs)
    write_config(create_config(log_configs, metric_configs))


if __name__ == "__main__":
    main()
