# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _setup_python
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
return if node['conditions']['ami_bootstrapped']

install_pyenv node['cfncluster']['python-version'] do
  prefix node['cfncluster']['system_pyenv_root']
end

activate_virtual_env node['cfncluster']['cookbook_virtualenv'] do
  pyenv_path node['cfncluster']['cookbook_virtualenv_path']
  python_version node['cfncluster']['python-version']
  requirements_path "requirements.txt"
  not_if { ::File.exist?("#{node['cfncluster']['cookbook_virtualenv_path']}/bin/activate") }
end

activate_virtual_env node['cfncluster']['node_virtualenv'] do
  pyenv_path node['cfncluster']['node_virtualenv_path']
  python_version node['cfncluster']['python-version']
  not_if { ::File.exist?("#{node['cfncluster']['node_virtualenv_path']}/bin/activate") }
end

bash 'install CloudFormation helpers' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-CFNTOOLS
      set -e
      region="#{node['cfncluster']['cfn_region']}"
      bucket="s3.amazonaws.com"
      [[ ${region} =~ ^cn- ]] && bucket="s3.cn-north-1.amazonaws.com.cn/cn-north-1-aws-parallelcluster"
      curl --retry 3 -L -o aws-cfn-bootstrap-py3-latest.tar.gz https://${bucket}/cloudformation-examples/aws-cfn-bootstrap-py3-latest.tar.gz
      #{node['cfncluster']['cookbook_virtualenv_path']}/bin/pip install aws-cfn-bootstrap-py3-latest.tar.gz
  CFNTOOLS
  creates "#{node['cfncluster']['cookbook_virtualenv_path']}/bin/cfn-hup"
end
