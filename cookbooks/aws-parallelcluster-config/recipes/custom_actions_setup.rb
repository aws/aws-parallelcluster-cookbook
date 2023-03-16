# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: custom_actions_setup
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

template "#{node['cluster']['scripts_dir']}/fetch_and_run" do
  source 'init/fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
end

cookbook_file "#{node['cluster']['scripts_dir']}/custom_action_executor.py" do
  source 'custom_action_executor/custom_action_executor.py'
  owner 'root'
  group 'root'
  mode '0755'
  not_if { ::File.exist?("#{node['cluster']['scripts_dir']}/custom_action_executor.py") }
end
