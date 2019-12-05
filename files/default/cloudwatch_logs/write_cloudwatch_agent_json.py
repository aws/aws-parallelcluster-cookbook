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


AWS_CLOUDWATCH_CFG_PATH = '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json'


def parse_args():
    """Parse CL args and return an argparse.Namespace."""
    parser = argparse.ArgumentParser(
        description='Create the cloudwatch agent config file'
    )
    parser.add_argument('--config',
                        help='Path to JSON file describing logs that should be monitored',
                        required=True)
    parser.add_argument('--platform',
                        help='OS family of this instance',
                        choices=['amazon', 'centos', 'ubuntu'],
                        required=True)
    parser.add_argument('--log-group',
                        help='Name of the log group',
                        required=True)
    parser.add_argument('--node-role',
                        required=True,
                        choices=['MasterServer', 'ComputeFleet'],
                        help='Role this node plays in the cluster '
                             '(i.e., is it a compute node or the master?)')
    parser.add_argument('--scheduler',
                        required=True,
                        choices=['slurm', 'sge', 'torque', 'awsbatch'],
                        help='Scheduler')
    return parser.parse_args()


def gethostname():
    """Return hostname of this instance."""
    return socket.gethostname().split('.')[0]


def write_config(config):
    """Write config to AWS_CLOUDWATCH_CFG_PATH."""
    with open(AWS_CLOUDWATCH_CFG_PATH, 'w+') as output_config_file:
        json.dump(config, output_config_file, indent=4)


def add_log_group_name_params(log_group_name, configs):
    """Add a "log_group_name": log_group_name to every config."""
    for config in configs:
        config.update({'log_group_name': log_group_name})
    return configs


def add_instance_log_stream_prefixes(configs):
    """Prefix all log_stream_name fields with instance identifiers."""
    for config in configs:
        config['log_stream_name'] = '{host}.{{instance_id}}.{log_stream_name}'.format(
            host=gethostname(),
            log_stream_name=config['log_stream_name']
        )
    return configs


def read_data(config_path):
    """Read in log configuration data from config_path."""
    with open(config_path) as infile:
        return json.load(infile)


def select_configs_for_scheduler(configs, scheduler):
    """Filter out from configs those entries whose 'schedulers' list does not contain scheduler."""
    return [config for config in configs if scheduler in config['schedulers']]


def select_configs_for_node_role(configs, node_role):
    """Filter out from configs those entries whose 'node_roles' list does not contain node_role."""
    return [config for config in configs if node_role in config['node_roles']]


def select_configs_for_platform(configs, platform):
    """Filter out from configs those entries whose 'platforms' list does not contain platform."""
    return [config for config in configs if platform in config['platforms']]


def get_node_info():
    """Return the information encoded in the JSON file at /etc/chef/dna.json."""
    node_info = {}
    dna_path = "/etc/chef/dna.json"
    if os.path.isfile(dna_path):
        with open(dna_path) as node_info_file:
            node_info = json.load(node_info_file).get("cfncluster")
    return node_info


def select_configs_for_feature(configs):
    """Filter out from configs those entries whose 'feature_conditions' list contains an unsatisfied entry."""
    selected_configs = []
    node_info = get_node_info()
    for config in configs:
        conditions = config.get("feature_conditions", [])
        for condition in conditions:
            node_info_key = condition.get("dna_key")
            if node_info.get(node_info_key) not in condition.get("satisfying_values"):
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
        config['timestamp_format'] = timestamps_dict[config['timestamp_format_key']]
    return configs


def filter_output_fields(configs):
    """Remove fields that are not required by CloudWatch agent config file."""
    desired_keys = ['log_stream_name', 'file_path', 'timestamp_format', 'log_group_name']
    return [{desired_key: config[desired_key] for desired_key in desired_keys} for config in configs]


def create_config(log_configs):
    """Return a dict representing the structure of the output JSON."""
    return {
        "logs": {
            "logs_collected": {
                "files": {
                    "collect_list": log_configs
                }
            },
            "log_stream_name": "{host}.{{instance_id}}.default-log-stream".format(host=gethostname())
        }
    }


def main():
    """Create cloudwatch agent config file."""
    args = parse_args()
    config_data = read_data(args.config)
    log_configs = select_logs(config_data['log_configs'], args)
    log_configs = add_timestamps(log_configs, config_data['timestamp_formats'])
    log_configs = add_log_group_name_params(args.log_group, log_configs)
    log_configs = add_instance_log_stream_prefixes(log_configs)
    log_configs = filter_output_fields(log_configs)
    write_config(create_config(log_configs))


if __name__ == '__main__':
    main()
