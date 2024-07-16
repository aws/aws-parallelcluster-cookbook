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

remote_file "#{node['cluster']['base_dir']}/node-dependencies.tgz" do
  source "#{node['cluster']['artifacts_s3_url']}/dependencies/PyPi/#{node['kernel']['machine']}/node-dependencies.tgz"
  mode '0644'
  retries 3
  retry_delay 5
  action :create_if_missing
end

bash 'pip install' do
  user 'root'
  group 'root'
  cwd "#{node['cluster']['base_dir']}"
  code <<-REQ
    set -e
    tar xzf node-dependencies.tgz
    cd node
    #{virtualenv_path}/bin/pip install * -f ./ --no-index
    REQ
end

if is_custom_node?
  include_recipe 'aws-parallelcluster-computefleet::custom_parallelcluster_node'
else
  remote_file "#{Chef::Config[:file_cache_path]}/aws-parallelcluster-node.tgz" do
    source "#{node['cluster']['artifacts_s3_url']}/dependencies/node/aws-parallelcluster-node.tgz"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash "install official aws-parallelcluster-node" do
    cwd Chef::Config[:file_cache_path]
    code <<-NODE
    set -e
    [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
    echo "PATH is $PATH"
    source #{node_virtualenv_path}/bin/activate
    pip uninstall --yes aws-parallelcluster-node
    rm -fr aws-parallelcluster-node
    mkdir aws-parallelcluster-node
    tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-node
    cd aws-parallelcluster-node/*aws-parallelcluster-node-*
    pip install .
    deactivate
  NODE
  end
end
