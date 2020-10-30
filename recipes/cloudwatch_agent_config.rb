# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: cloudwatch_agent_config
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Be sure to have AWS cloudwatch agent installed
include_recipe "aws-parallelcluster::cloudwatch_agent_install"

config_script_path = '/usr/local/bin/write_cloudwatch_agent_json.py'
cookbook_file 'write_cloudwatch_agent_json.py' do
  not_if { ::File.exist?(config_script_path) }
  source 'cloudwatch_logs/write_cloudwatch_agent_json.py'
  path config_script_path
  user 'root'
  group 'root'
  mode '0755'
end

config_data_path = '/usr/local/etc/cloudwatch_log_files.json'
cookbook_file 'cloudwatch_log_files.json' do
  not_if { ::File.exist?(config_data_path) }
  source 'cloudwatch_logs/cloudwatch_log_files.json'
  path config_data_path
  user 'root'
  group 'root'
  mode '0644'
end

config_schema_path = '/usr/local/etc/cloudwatch_log_files_schema.json'
cookbook_file 'cloudwatch_log_files_schema.json' do
  not_if { ::File.exist?(config_schema_path) }
  source 'cloudwatch_logs/cloudwatch_log_files_schema.json'
  path config_schema_path
  user 'root'
  group 'root'
  mode '0644'
end

validator_script_path = '/usr/local/bin/cloudwatch_log_configs_util.py'
cookbook_file 'cloudwatch_log_configs_util.py' do
  not_if { ::File.exist?(validator_script_path) }
  source 'cloudwatch_logs/cloudwatch_log_configs_util.py'
  path validator_script_path
  user 'root'
  group 'root'
  mode '0644'
end

execute "cloudwatch-config-validation" do
  user 'root'
  environment(
    'CW_LOGS_CONFIGS_SCHEMA_PATH' => config_schema_path,
    'CW_LOGS_CONFIGS_PATH' => config_data_path
  )
  command "#{node.default['cfncluster']['cookbook_virtualenv_path']}/bin/python #{validator_script_path}"
end

execute "cloudwatch-config-creation" do
  user 'root'
  environment(
    'LOG_GROUP_NAME' => "/aws/parallelcluster/#{node['cfncluster']['stack_name'].split(/^parallelcluster-/)[1]}",
    'SCHEDULER' => node['cfncluster']['cfn_scheduler'],
    'NODE_ROLE' => node['cfncluster']['cfn_node_type'],
    'CONFIG_DATA_PATH' => config_data_path
  )
  not_if { ::File.exist?('/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json') }
  command "#{node.default['cfncluster']['cookbook_virtualenv_path']}/bin/python #{config_script_path} "\
          "--platform #{node['platform']} --config $CONFIG_DATA_PATH --log-group $LOG_GROUP_NAME "\
          "--scheduler $SCHEDULER --node-role $NODE_ROLE"
end

execute "cloudwatch-agent-start" do
  user 'root'
  command "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
  not_if do
    system("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running") ||
      node['cfncluster']['cfn_cluster_cw_logging_enabled'] != 'true'
  end
end
