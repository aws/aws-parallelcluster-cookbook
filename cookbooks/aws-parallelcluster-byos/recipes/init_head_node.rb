# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster-byos
# Recipe:: init_head_node
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

# Export /opt/parallelcluster/shared
nfs_export node['cluster']['shared_dir'] do
  network get_vpc_cidr_list
  writeable true
  options ['no_root_squash']
end

execute_event_handler 'HeadInit' do
  event_command(lazy { node['cluster']['config'].dig(:Scheduling, :ByosSettings, :SchedulerDefinition, :Events, :HeadInit, :ExecuteCommand, :Command) })
end
