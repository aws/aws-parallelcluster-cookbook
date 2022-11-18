# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: update_head_node
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

ruby_block "update_shared_storages" do
  block do
    run_context.include_recipe 'aws-parallelcluster-config::update_shared_storages'
  end
  only_if { are_mount_or_unmount_required? }
end

execute_event_handler 'HeadClusterUpdate' do
  event_command(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :SchedulerDefinition, :Events, :HeadClusterUpdate, :ExecuteCommand, :Command) })
end

# The updated cfnconfig will be used by post update custom scripts
template '/etc/parallelcluster/cfnconfig' do
  source 'init/cfnconfig.erb'
  cookbook 'aws-parallelcluster-config'
  mode '0644'
end
