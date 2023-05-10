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
return if redhat_ubi?

install_pyenv_new 'pyenv for default python version'

activate_virtual_env node_virtualenv_name do
  pyenv_path node_virtualenv_path
  python_version node_python_version
  not_if { ::File.exist?("#{virtualenv_path}/bin/activate") }
end

if !node['cluster']['custom_node_package'].nil? && !node['cluster']['custom_node_package'].empty?
  # Install custom aws-parallelcluster-node package
  bash "install aws-parallelcluster-node" do
    cwd Chef::Config[:file_cache_path]
    code <<-NODE
      set -e
      [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
      echo "PATH is $PATH"
      source #{virtualenv_path}/bin/activate
      pip uninstall --yes aws-parallelcluster-node
      if [[ "#{node['cluster']['custom_node_package']}" =~ ^s3:// ]]; then
        custom_package_url=$(#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 presign #{node['cluster']['custom_node_package']} --region #{node['cluster']['region']})
      else
        custom_package_url=#{node['cluster']['custom_node_package']}
      fi
      curl --retry 3 -L -o aws-parallelcluster-node.tgz ${custom_package_url}
      mkdir aws-parallelcluster-custom-node
      tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
      cd aws-parallelcluster-custom-node/*aws-parallelcluster-node-*
      pip install .
      deactivate
    NODE
  end
else
  pyenv_pip 'aws-parallelcluster-node' do
    version node['cluster']['parallelcluster-node-version']
    virtualenv virtualenv_path
  end
end
