# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: init
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

include_recipe "aws-parallelcluster-platform::enable_chef_error_handler"

os_type 'Validate OS type specified by the user is the same as the OS identified by Ohai'

# Validate init system
raise "Init package #{node['init_package']} not supported." unless systemd? || on_docker?

include_recipe "aws-parallelcluster-environment::cfnconfig_mixed"
include_recipe "aws-parallelcluster-environment::mount_shared"

fetch_config 'Fetch and load cluster configs'
cloudwatch "Configure CloudWatch" do
  action :configure
end

include_recipe "aws-parallelcluster-platform::custom_actions_setup"

include_recipe "aws-parallelcluster-environment::network_interfaces"

include_recipe "aws-parallelcluster-computefleet::init"
include_recipe "aws-parallelcluster-slurm::init"
include_recipe "aws-parallelcluster-scheduler-plugin::init"

include_recipe 'aws-parallelcluster-environment::imds'
include_recipe "aws-parallelcluster-environment::directory_service"
