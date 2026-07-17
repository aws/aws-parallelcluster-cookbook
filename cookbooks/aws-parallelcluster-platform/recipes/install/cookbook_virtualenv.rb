# frozen_string_literal: true
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

virtualenv_path = cookbook_virtualenv_path
dependency_package_name = "pypi-cookbook-dependencies-#{node['cluster']['python-major-minor-version']}-#{node['kernel']['machine']}"
pypi_s3_uri = "#{node['cluster']['artifacts_s3_url']}/dependencies/PyPi/#{node['kernel']['machine']}/#{dependency_package_name}.tgz"

node.default['cluster']['cookbook_virtualenv_path'] = virtualenv_path
node_attributes "dump node attributes"

# TODO: find a way to make this code work on ubi8
return if redhat_on_docker?

install_pyenv 'pyenv for default python version'

activate_virtual_env cookbook_virtualenv_name do
  pyenv_path cookbook_virtualenv_path
  python_version cookbook_python_version
  not_if { ::File.exist?("#{cookbook_virtualenv_path}/bin/activate") }
end

# Install dependencies based on install_python_from_internet setting
# When true, dependencies are installed from PyPI (for testing new Python versions)
# When false (default), dependencies are installed from S3 pre-built packages (production mode)
if node['cluster']['install_python_from_internet']
  cookbook_file "#{node['cluster']['base_dir']}/cookbook-requirements.txt" do
    source 'cookbook_virtualenv/requirements.txt'
    cookbook 'aws-parallelcluster-platform'
    mode '0644'
  end

  bash 'pip install cookbook dependencies from internet' do
    user 'root'
    group 'root'
    code <<-REQ
      set -e
      #{virtualenv_path}/bin/pip install -r #{node['cluster']['base_dir']}/cookbook-requirements.txt
    REQ
  end
else
  remote_file "#{node['cluster']['base_dir']}/cookbook-dependencies.tgz" do
    source pypi_s3_uri
    mode '0644'
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  bash 'pip install cookbook dependencies from S3' do
    user 'root'
    group 'root'
    cwd "#{node['cluster']['base_dir']}"
    code <<-REQ
      set -e
      tar xzf cookbook-dependencies.tgz
      cd #{dependency_package_name}
      #{virtualenv_path}/bin/pip install * -f ./ --no-index
    REQ
  end
end
