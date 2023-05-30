# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: install
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

return if platform?('redhat')

# setup the user accounts
include_recipe "aws-parallelcluster-scheduler-plugin::install_user"

directory node['cluster']['scheduler_plugin']['local_dir'] do
  owner node['cluster']['scheduler_plugin']['user']
  group node['cluster']['scheduler_plugin']['user']
  mode '0755'
  action :create
end

directory node['cluster']['scheduler_plugin']['handler_dir'] do
  owner node['cluster']['scheduler_plugin']['user']
  group node['cluster']['scheduler_plugin']['user']
  mode '0755'
  action :create
end

directory node['cluster']['scheduler_plugin']['shared_dir'] do
  owner node['cluster']['scheduler_plugin']['user']
  group node['cluster']['scheduler_plugin']['user']
  mode '0755'
  action :create
end

# setup Pyenv and Virtualenv under node['cluster']['scheduler_plugin']['shared_dir']
include_recipe "aws-parallelcluster-scheduler-plugin::install_python"

cookbook_file '/usr/local/sbin/invoke-scheduler-plugin-event-handler.sh' do
  source 'event_handler/invoke-scheduler-plugin-event-handler.sh'
  owner 'root'
  group 'root'
  mode '0755'
end
