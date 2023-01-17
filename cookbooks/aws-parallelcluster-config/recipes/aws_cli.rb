# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: aws_cli
#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Users to configure the AWS CLI for.
# We configure the AWS CLI for all the users that are created by ParallelCluster and must interact with AWS.
users = node['cluster']['head_node_imds_allowed_users']

# AWS CLI configurations to set.
# Note: only the configurations with a not nil value will be set.
region = node['cluster']['region']
configurations = {
  'ca_bundle' =>  region.start_with?('us-iso') ? "/etc/pki/#{region}/certs/ca-bundle.pem" : nil,
}

def set_aws_cli_configuration(config_name, expected_value, user)
  execute "Setting AWS CLI configuration for user #{user}: #{config_name} set to '#{expected_value}'" do
    user user
    login true
    command "aws configure set #{config_name} #{expected_value}"
  end
end

# AWS CLI is explicitly configured only in US iso regions.
if region.start_with?('us-iso')
  users.each do |user|
    configurations.each do |config_name, config_value|
      next if config_value.nil?
      set_aws_cli_configuration(config_name, config_value, user)
    end
  end
end
