# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: aws_batch_config
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Use these recipes to add a custom scheduler
include_recipe 'aws-parallelcluster::base_config'
include_recipe 'aws-parallelcluster::base_install'

# Install aws-parallelcluster-awsbatch-cli.cfg
awsbatch_cli_config_dir = "/home/#{node['cfncluster']['cfn_cluster_user']}/.parallelcluster/"

directory awsbatch_cli_config_dir do
  owner node['cfncluster']['cfn_cluster_user']
  group node['cfncluster']['cfn_cluster_user']
  recursive true
end

template "#{awsbatch_cli_config_dir}/awsbatch-cli.cfg" do
  source 'awsbatch-cli.cfg.erb'
  owner node['cfncluster']['cfn_cluster_user']
  group node['cfncluster']['cfn_cluster_user']
  mode '0644'
end

# Check whether install a custom aws-parallelcluster package (for aws-parallelcluster-awsbatchcli) or the standard one
if !node['cfncluster']['custom_awsbatchcli_package'].nil? && !node['cfncluster']['custom_awsbatchcli_package'].empty?
  # Install custom aws-parallelcluster package
  bash "install aws-parallelcluster-awsbatch-cli" do
    cwd Chef::Config[:file_cache_path]
    code <<-CLI
      set -e
      curl --retry 3 -L -o aws-parallelcluster.tgz #{node['cfncluster']['custom_awsbatchcli_package']}
      mkdir aws-parallelcluster-custom-cli
      tar -xzf aws-parallelcluster.tgz --directory aws-parallelcluster-custom-cli
      cd aws-parallelcluster-custom-cli/*aws-parallelcluster-*
      pip install cli/
    CLI
  end
# Install aws-parallelcluster package (for aws-parallelcluster-awsbatchcli)
elsif node['platform_family'] == 'rhel' && node['platform_version'].to_i < 7
  # For CentOS 6 use shell_out function in order to have a correct PATH needed to compile aws-parallelcluster dependencies
  ruby_block "pip_install_parallelcluster" do
    block do
      pip_install_package('aws-parallelcluster', node['cfncluster']['cfncluster-version'])
    end
  end
else
  python_package "aws-parallelcluster" do
    version node['cfncluster']['cfncluster-version']
    retries 3
    retry_delay 5
  end
end
