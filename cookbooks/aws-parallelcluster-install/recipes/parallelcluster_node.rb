# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: node
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.
# Check whether install a custom aws-parallelcluster-node package or the standard one

# TODO: find a way to make this code work on ubi8
return if redhat_ubi?

install_pyenv node['cluster']['python-version'] do
  prefix node['cluster']['system_pyenv_root']
end

activate_virtual_env node['cluster']['node_virtualenv'] do
  pyenv_path node['cluster']['node_virtualenv_path']
  python_version node['cluster']['python-version']
  not_if { ::File.exist?("#{node['cluster']['node_virtualenv_path']}/bin/activate") }
end

if !node['cluster']['custom_node_package'].nil? && !node['cluster']['custom_node_package'].empty?
  # Install custom aws-parallelcluster-node package
  include_recipe "aws-parallelcluster-install::custom_parallelcluster_node"
else
  pyenv_pip 'aws-parallelcluster-node' do
    version node['cluster']['parallelcluster-node-version']
    virtualenv node['cluster']['node_virtualenv_path']
  end
end
