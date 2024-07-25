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

virtualenv_path = node_virtualenv_path

node.default['cluster']['node_virtualenv_path'] = virtualenv_path
node_attributes "dump node attributes"

# TODO: find a way to make this code work on ubi8
return if redhat_on_docker?

install_pyenv 'pyenv for default python version'

activate_virtual_env node_virtualenv_name do
  pyenv_path node_virtualenv_path
  python_version node_python_version
  not_if { ::File.exist?("#{virtualenv_path}/bin/activate") }
end

if aws_region.start_with?("us-iso") && !is_custom_node?
  node.default['cluster']['custom_node_package'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/node/aws-parallelcluster-node.tgz"
end

if is_custom_node?
  include_recipe 'aws-parallelcluster-computefleet::custom_parallelcluster_node'
else
  execute "install official aws-parallelcluster-node" do
    command "#{virtualenv_path}/bin/pip install aws-parallelcluster-node==#{node['cluster']['parallelcluster-node-version']}"
  end
end
