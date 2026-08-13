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
# Use --no-build-isolation when installing from S3 pre-built deps, omit when installing from internet
pip_install_flags = node['cluster']['install_python_from_internet'] ? "" : "--no-build-isolation"
command = "pip install . #{pip_install_flags}".strip

dependency_package_name = "pypi-node-dependencies-#{node['cluster']['python-major-minor-version']}-#{node['kernel']['machine']}"
dependency_folder_name = dependency_package_name

# Install dependencies from S3 pre-built packages (production mode)
# When install_python_from_internet is true, dependencies are installed from PyPI instead
unless node['cluster']['install_python_from_internet']
  remote_file "#{node['cluster']['base_dir']}/node-dependencies.tgz" do
    source "#{node['cluster']['artifacts_s3_url']}/dependencies/PyPi/#{node['kernel']['machine']}/#{dependency_package_name}.tgz"
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash 'pip install node dependencies from S3' do
    user 'root'
    group 'root'
    cwd "#{node['cluster']['base_dir']}"
    code <<-REQ
      set -e
      tar xzf node-dependencies.tgz
      cd #{dependency_folder_name}
      #{node_virtualenv_path}/bin/pip install * -f ./ --no-index
    REQ
  end
end

bash "install aws-parallelcluster-node from #{node['cluster']['custom_node_package']}" do
  cwd Chef::Config[:file_cache_path]
  code <<-NODE
    set -e
    [[ ":$PATH:" != *":/usr/local/bin:"* ]] && PATH="/usr/local/bin:${PATH}"
    echo "PATH is $PATH"
    source #{node_virtualenv_path}/bin/activate
    pip uninstall --yes aws-parallelcluster-node
    if [[ "#{node['cluster']['custom_node_package']}" =~ ^s3:// ]]; then
      custom_package_url=$(#{cookbook_virtualenv_path}/bin/aws s3 presign #{node['cluster']['custom_node_package']} --region #{aws_region} --endpoint-url https://s3.#{aws_region}.#{aws_domain})
    else
      custom_package_url=#{node['cluster']['custom_node_package']}
    fi
    delays=(1 2 4 8 16 32 64 128 256)
    for i in {0..8}; do
      curl -v -L -o aws-parallelcluster-node.tgz ${custom_package_url} && break
      echo "Curl attempt $((i+1)) failed, retrying in ${delays[$i]}s..."
      sleep ${delays[$i]}
    done
    rm -fr aws-parallelcluster-custom-node
    mkdir aws-parallelcluster-custom-node
    tar -xzf aws-parallelcluster-node.tgz --directory aws-parallelcluster-custom-node
    cd aws-parallelcluster-custom-node/*aws-parallelcluster-node*
    #{command}
    deactivate
  NODE
end
