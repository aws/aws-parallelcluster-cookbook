# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
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

return unless node['cluster']['scheduler'] == 'plugin'

# create system user
include_recipe "aws-parallelcluster-scheduler-plugin::init_user"

file "#{node['cluster']['scheduler_plugin']['handler_log_err']}" do
  owner node['cluster']['scheduler_plugin']['user']
  group node['cluster']['scheduler_plugin']['group']
  mode '0640'
end

file "#{node['cluster']['scheduler_plugin']['handler_log_out']}" do
  owner node['cluster']['scheduler_plugin']['user']
  group node['cluster']['scheduler_plugin']['group']
  mode '0640'
end

case node['cluster']['node_type']
when 'HeadNode'
  include_recipe 'aws-parallelcluster-scheduler-plugin::init_head_node'
when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-scheduler-plugin::init_compute'
else
  raise "node_type must be HeadNode or ComputeFleet"
end
