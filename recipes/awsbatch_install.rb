# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: aws_batch_install
#
# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

include_recipe 'aws-parallelcluster::base_install'

# Add awsbatch virtualenv to default path
template "/etc/profile.d/pcluster_awsbatchcli.sh" do
  source "pcluster_awsbatchcli.sh.erb"
  owner 'root'
  group 'root'
  mode '0644'
end

# Check whether install a custom aws-parallelcluster package (for aws-parallelcluster-awsbatchcli) or the standard one
# Install awsbatch cli into awsbatch virtual env
if !node['cluster']['custom_awsbatchcli_package'].nil? && !node['cluster']['custom_awsbatchcli_package'].empty?
  # Install custom aws-parallelcluster package
  bash "install aws-parallelcluster-awsbatch-cli" do
    cwd Chef::Config[:file_cache_path]
    code <<-CLI
      set -e
      if [[ "#{node['cluster']['custom_awsbatchcli_package']}" =~ ^s3:// ]]; then
        custom_package_url=$(#{node['cluster']['cookbook_virtualenv_path']}/bin/aws s3 presign #{node['cluster']['custom_awsbatchcli_package']} --region #{node['cluster']['region']})
      else
        custom_package_url=#{node['cluster']['custom_awsbatchcli_package']}
      fi
      curl --retry 3 -L -o aws-parallelcluster.tgz ${custom_package_url}
      mkdir aws-parallelcluster-custom-cli
      tar -xzf aws-parallelcluster.tgz --directory aws-parallelcluster-custom-cli
      cd aws-parallelcluster-custom-cli/*aws-parallelcluster-*
      #{node['cluster']['awsbatch_virtualenv_path']}/bin/pip install cli/
    CLI
  end
else
  # Install aws-parallelcluster package (for aws-parallelcluster-awsbatchcli)
  execute "pip_install_parallelcluster" do
    command "#{node['cluster']['awsbatch_virtualenv_path']}/bin/pip install aws-parallelcluster==#{node['cluster']['parallelcluster-version']}"
  end
end
