# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: base
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

# Install custom aws-parallelcluster-node package

# TODO: once the pyenv Chef resource supports installing packages from a path (e.g. `pip install .`), convert the
# bash block to a recipe that uses the pyenv resource.

bash "install custom aws-parallelcluster-node" do
  cwd Chef::Config[:file_cache_path]
  code <<-NODE
    set -e
    [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
    echo "PATH is $PATH"
    source #{node['cluster']['node_virtualenv_path']}/bin/activate
    pip uninstall --yes aws-parallelcluster-node
    if [[ "#{node['cluster']['custom_node_package']}" =~ ^s3:// ]]; then
      custom_package_url=$(#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 presign #{node['cluster']['custom_node_package']} --region #{node['cluster']['region']})
    else
      custom_package_url=#{node['cluster']['custom_node_package']}
    fi
    curl --retry 3 -L -o aws-parallelcluster-node.tgz ${custom_package_url}
    rm -fr aws-parallelcluster-custom-node
    mkdir aws-parallelcluster-custom-node
    tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
    cd aws-parallelcluster-custom-node/*aws-parallelcluster-node-*
    pip install .
    deactivate
  NODE
end
