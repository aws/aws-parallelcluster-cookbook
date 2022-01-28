# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: init_head_node
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

fetch_artifacts 'Fetch Cluster Shared Artifacts' do
  plugin_resources(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :SchedulerDefinition, :PluginResources) })
end

execute_event_handler 'HeadInit' do
  event_command(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :SchedulerDefinition, :Events, :HeadInit, :ExecuteCommand, :Command) })
end
