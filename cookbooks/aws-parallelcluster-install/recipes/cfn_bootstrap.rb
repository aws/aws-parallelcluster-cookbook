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

# TODO: find a way to make this code work on ubi8
return if redhat_ubi?

# FIXME: Python install for cfn_bootstrap_virtualenv due to a bug with cfn-hup
install_pyenv node['cluster']['python-version-cfn_bootstrap_virtualenv'] do
  prefix node['cluster']['system_pyenv_root']
end

# Install cfn_bootstrap virtualenv
activate_virtual_env node['cluster']['cfn_bootstrap_virtualenv'] do
  pyenv_path node['cluster']['cfn_bootstrap_virtualenv_path']
  python_version node['cluster']['python-version-cfn_bootstrap_virtualenv']
  not_if { ::File.exist?("#{node['cluster']['cfn_bootstrap_virtualenv_path']}/bin/activate") }
end

bash "Install CloudFormation helpers from #{node['cluster']['cfn_bootstrap']['package']}" do
  user 'root'
  group 'root'
  cwd '/tmp'
  code <<-CFNTOOLS
      set -e
      region="#{node['cluster']['region']}"
      bucket="s3.amazonaws.com"
      [[ ${region} =~ ^cn- ]] && bucket="s3.cn-north-1.amazonaws.com.cn/cn-north-1-aws-parallelcluster"
      curl --retry 3 -L -o #{node['cluster']['cfn_bootstrap']['package']} https://${bucket}/cloudformation-examples/#{node['cluster']['cfn_bootstrap']['package']}
      #{node['cluster']['cfn_bootstrap_virtualenv_path']}/bin/pip install #{node['cluster']['cfn_bootstrap']['package']}
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

# Add cfn-hup runner
template "#{node['cluster']['scripts_dir']}/cfn-hup-runner.sh" do
  source "base/cfn-hup-runner.sh.erb"
  owner 'root'
  group 'root'
  mode '0744'
end
