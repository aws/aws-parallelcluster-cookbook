# frozen_string_literal: true

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

# TODO: find a way to make this code work on ubi8
virtualenv_name = 'cfn_bootstrap_virtualenv'
pyenv_root = node['cluster']['system_pyenv_root']
# FIXME: Python Version cfn_bootstrap_virtualenv due to a bug with cfn-hup
python_version = '3.9.19'
virtualenv_path = "#{pyenv_root}/versions/#{python_version}/envs/#{virtualenv_name}"

node.default['cluster']['cfn_bootstrap_virtualenv_path'] = virtualenv_path
node_attributes "dump node attributes"

return if redhat_on_docker?

install_pyenv 'pyenv for cfn_bootstrap' do
  python_version python_version
end

activate_virtual_env virtualenv_name do
  pyenv_path virtualenv_path
  python_version python_version
  not_if { ::File.exist?("#{virtualenv_path}/bin/activate") }
end

cfnbootstrap_version = '2.0-28'
cfnbootstrap_package = "aws-cfn-bootstrap-py3-#{cfnbootstrap_version}.tar.gz"

region = node['cluster']['region']
bucket = region.start_with?('cn-') ? 's3.cn-north-1.amazonaws.com.cn/cn-north-1-aws-parallelcluster' : "s3.amazonaws.com"

remote_file "/tmp/#{cfnbootstrap_package}" do
  source "https://#{bucket}/cloudformation-examples/#{cfnbootstrap_package}"
  retries 3
  retry_delay 5
end

bash "Install CloudFormation helpers from #{cfnbootstrap_package}" do
  user 'root'
  group 'root'
  cwd '/tmp'
  code "#{virtualenv_path}/bin/pip install #{cfnbootstrap_package}"
  creates "#{virtualenv_path}/bin/cfn-hup"
end

# Add cfn_bootstrap virtualenv to default path
template "/etc/profile.d/pcluster.sh" do
  source "cfn_bootstrap/pcluster.sh.erb"
  owner 'root'
  group 'root'
  mode '0644'
  variables(cfn_bootstrap_virtualenv_path: virtualenv_path)
end

directory node['cluster']['scripts_dir'] do
  recursive true
end

# Add cfn-hup runner
template "#{node['cluster']['scripts_dir']}/cfn-hup-runner.sh" do
  source "cfn_bootstrap/cfn-hup-runner.sh.erb"
  owner 'root'
  group 'root'
  mode '0744'
  variables(cfn_bootstrap_virtualenv_path: virtualenv_path)
end
