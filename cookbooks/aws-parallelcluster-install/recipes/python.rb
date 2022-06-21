# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: python
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

install_pyenv node['cluster']['python-version'] do
  prefix node['cluster']['system_pyenv_root']
end

activate_virtual_env node['cluster']['cookbook_virtualenv'] do
  pyenv_path node['cluster']['cookbook_virtualenv_path']
  python_version node['cluster']['python-version']
  requirements_path "requirements.txt"
  not_if { ::File.exist?("#{node['cluster']['cookbook_virtualenv_path']}/bin/activate") }
end

activate_virtual_env node['cluster']['node_virtualenv'] do
  pyenv_path node['cluster']['node_virtualenv_path']
  python_version node['cluster']['python-version']
  not_if { ::File.exist?("#{node['cluster']['node_virtualenv_path']}/bin/activate") }
end

# Install awsbatch virtualenv
activate_virtual_env node['cluster']['awsbatch_virtualenv'] do
  pyenv_path node['cluster']['awsbatch_virtualenv_path']
  python_version node['cluster']['python-version']
  not_if { ::File.exist?("#{node['cluster']['awsbatch_virtualenv_path']}/bin/activate") }
end

# Install cfn_bootstrap virtualenv
activate_virtual_env node['cluster']['cfn_bootstrap_virtualenv'] do
  pyenv_path node['cluster']['cfn_bootstrap_virtualenv_path']
  python_version node['cluster']['python-version']
  not_if { ::File.exist?("#{node['cluster']['cfn_bootstrap_virtualenv_path']}/bin/activate") }
end

bash 'install CloudFormation helpers' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-CFNTOOLS
      set -e
      region="#{node['cluster']['region']}"
      bucket="s3.amazonaws.com"
      [[ ${region} =~ ^cn- ]] && bucket="s3.cn-north-1.amazonaws.com.cn/cn-north-1-aws-parallelcluster"
      curl --retry 3 -L -o aws-cfn-bootstrap-py3-latest.tar.gz https://${bucket}/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
      #{node['cluster']['cfn_bootstrap_virtualenv_path']}/bin/pip install aws-cfn-bootstrap-py3-latest.tar.gz
  CFNTOOLS
  creates "#{node['cluster']['cfn_bootstrap_virtualenv_path']}/bin/cfn-hup"
end

# Add cfn_bootstrap virtualenv to default path
template "/etc/profile.d/pcluster.sh" do
  source "base/pcluster.sh.erb"
  owner 'root'
  group 'root'
  mode '0644'
end
