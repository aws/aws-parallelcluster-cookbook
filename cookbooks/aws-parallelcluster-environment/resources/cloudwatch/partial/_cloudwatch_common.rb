# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

action :cloudwatch_prerequisite do
  # Do nothing
end

action :setup do
  directory node['cluster']['sources_dir'] do
    recursive true
  end

  action_cloudwatch_prerequisite

  public_key_local_path = "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.gpg"
  remote_file public_key_local_path do
    source 'https://s3.amazonaws.com/amazoncloudwatch-agent/assets/amazon-cloudwatch-agent.gpg'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # Set the s3 domain name to use for all download URLs
  s3_domain = "https://s3.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}"

  # Set URLs used to download the package and expected signature based on platform
  package_url_prefix = "#{s3_domain}/amazoncloudwatch-agent-#{node['cluster']['region']}"
  arch_url_component = arm_instance? ? 'arm64' : 'amd64'
  Chef::Log.info("Platform for cloudwatch is #{platform_url_component}")
  package_url = [
    package_url_prefix,
    platform_url_component,
    arch_url_component,
    'latest',
    "amazon-cloudwatch-agent.#{package_extension}",
  ].join('/')
  signature_url = "#{package_url}.sig"
  signature_path = "#{package_path}.sig"

  # Download package and its expected signature
  remote_file signature_path do
    source signature_url
    retries 3
    retry_delay 5
    action :create_if_missing
  end
  remote_file package_path do
    source package_url
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # Import cloudwatch agent's public key to the keyring
  execute 'import-cloudwatch-agent-key' do
    command "gpg --import #{public_key_local_path}"
  end

  # Verify that cloudwatch agent's public key has expected fingerprint
  execute 'verify-cloudwatch-agent-public-key-fingerprint' do
    command 'gpg --list-keys --fingerprint "Amazon CloudWatch Agent" | grep "9376 16F3 450B 7D80 6CBD  9725 D581 6730 3B78 9C72"'
  end

  # Verify that the cloudwatch agent package matches its expected signature
  execute 'verify-cloudwatch-agent-rpm-signature' do
    command "gpg --verify #{signature_path} #{package_path}"
  end

  action_cloudwatch_install_package
end

action_class do
  def package_path
    "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.#{package_extension}"
  end
end

action :configure do
  config_script_path = '/usr/local/bin/write_cloudwatch_agent_json.py'
  cookbook_file 'write_cloudwatch_agent_json.py' do
    action :create_if_missing
    source 'cloudwatch/write_cloudwatch_agent_json.py'
    cookbook 'aws-parallelcluster-environment'
    path config_script_path
    user 'root'
    group 'root'
    mode '0755'
  end

  config_data_path = '/usr/local/etc/cloudwatch_agent_config.json'
  cookbook_file 'cloudwatch_agent_config.json' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_config.json'
    cookbook 'aws-parallelcluster-environment'
    path config_data_path
    user 'root'
    group 'root'
    mode '0644'
  end

  config_schema_path = '/usr/local/etc/cloudwatch_agent_config_schema.json'
  cookbook_file 'cloudwatch_agent_config_schema.json' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_config_schema.json'
    cookbook 'aws-parallelcluster-environment'
    path config_schema_path
    user 'root'
    group 'root'
    mode '0644'
  end

  validator_script_path = '/usr/local/bin/cloudwatch_agent_config_util.py'
  cookbook_file 'cloudwatch_agent_config_util.py' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_config_util.py'
    cookbook 'aws-parallelcluster-environment'
    path validator_script_path
    user 'root'
    group 'root'
    mode '0644'
  end

  common_module_path = '/usr/local/bin/cloudwatch_agent_common_utils.py'
  cookbook_file 'cloudwatch_agent_common_utils.py' do
    action :create_if_missing
    source 'cloudwatch/cloudwatch_agent_common_utils.py'
    cookbook 'aws-parallelcluster-environment'
    path common_module_path
    user 'root'
    group 'root'
    mode '0755'
  end

  execute "cloudwatch-config-validation" do
    user 'root'
    timeout 300
    environment(
      'CW_LOGS_CONFIGS_SCHEMA_PATH' => config_schema_path,
      'CW_LOGS_CONFIGS_PATH' => config_data_path
    )
    command "#{cookbook_virtualenv_path}/bin/python #{validator_script_path}"
  end unless redhat_on_docker?

  execute "cloudwatch-config-creation" do
    user 'root'
    timeout 300
    environment(
      'LOG_GROUP_NAME' => node['cluster']['log_group_name'],
      'SCHEDULER' => node['cluster']['scheduler'],
      'NODE_ROLE' => node['cluster']['node_type'],
      'CONFIG_DATA_PATH' => config_data_path
    )
    not_if { ::File.exist?('/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json') }

    command "#{cookbook_virtualenv_path}/bin/python #{config_script_path} "\
        "--platform #{node['platform']} --config $CONFIG_DATA_PATH --log-group $LOG_GROUP_NAME "\
        "--scheduler $SCHEDULER --node-role $NODE_ROLE"
  end unless redhat_on_docker?

  execute "cloudwatch-agent-start" do
    user 'root'
    timeout 300
    command "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s"
    not_if "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running"
  end unless node['cluster']['cw_logging_enabled'] != 'true' || on_docker?
end
