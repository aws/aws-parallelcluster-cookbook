#
# Cookbook:: aws-parallelcluster-environment
# Recipe:: login_nodes_keys
# frozen_string_literal: true

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

return if on_docker? || node['cluster']['scheduler'] == 'awsbatch'

keys_dir = "#{node['cluster']['shared_dir_login_nodes']}"
script_dir = "#{keys_dir}/scripts"
script_path = "#{script_dir}/keys-manager.sh"

sync_file_path = "#{keys_dir}/.login_nodes_keys_sync_file"

case node['cluster']['node_type']
when 'ComputeFleet'
  # Do nothing
when 'HeadNode'
  directory script_dir do
    owner 'root'
    group 'root'
    mode '0744'
    recursive true
  end

  cookbook_file script_path do
    source 'login_nodes/keys-manager.sh'
    owner 'root'
    group 'root'
    mode '0744'
  end

  execute 'Initialize Login Nodes keys' do
    command "bash #{script_path} --create --folder-path #{keys_dir}"
    user 'root'
  end

  write_sync_file(sync_file_path)

when 'LoginNode'

  wait_sync_file(sync_file_path)

  execute 'Import Login Nodes keys' do
    command "bash #{script_path} --import --folder-path #{keys_dir}"
    user 'root'
  end
else
  raise "node_type must be HeadNode or ComputeFleet or LoginNode"
end
