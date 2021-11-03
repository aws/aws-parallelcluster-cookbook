# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: invoke_byos_event_handler
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

event_name = node['cluster']['event_name']
raise "Event name not specified" if !event_name && event_name.empty?

load_cluster_config

fetch_artifacts 'Fetch Cluster Shared Artifacts' do
  plugin_resources(lazy { node['cluster']['config'].dig(:Scheduling, :ByosSettings, :SchedulerDefinition, :PluginResources) })
  force_download true
end

execute_event_handler event_name do
  event_command(lazy { node['cluster']['config'].dig(:Scheduling, :ByosSettings, :SchedulerDefinition, :Events, event_name, :ExecuteCommand, :Command) })
end
