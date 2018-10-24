#
# Cookbook Name:: cfncluster
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
include_recipe 'cfncluster::base_config'
include_recipe 'cfncluster::base_install'


# Install cfncluster-awsbatch-cli.cfg
awsbatch_cli_config_dir = "/home/#{node['cfncluster']['cfn_cluster_user']}/.cfncluster/"

directory "#{awsbatch_cli_config_dir}" do
  owner "#{node['cfncluster']['cfn_cluster_user']}"
  group "#{node['cfncluster']['cfn_cluster_user']}"
  recursive true
end

template "#{awsbatch_cli_config_dir}/awsbatch-cli.cfg" do
  source 'awsbatch-cli.cfg.erb'
  owner "#{node['cfncluster']['cfn_cluster_user']}"
  group "#{node['cfncluster']['cfn_cluster_user']}"
  mode '0644'
end

# Check whether install a custom cfncluster package (for cfncluster-awsbatchcli) or the standard one
if !node['cfncluster']['custom_awsbatchcli_package'].nil? && !node['cfncluster']['custom_awsbatchcli_package'].empty?
  # Install custom cfncluster package
  bash "install cfncluster-awsbatch-cli" do
    cwd '/tmp'
    code <<-EOH
      source /tmp/proxy.sh
      curl -v -L -o cfncluster.tgz #{node['cfncluster']['custom_awsbatchcli_package']}
      tar -xzf cfncluster.tgz
      cd cfncluster-*
      sudo pip install cli/
    EOH
  end
else
  # Install cfncluster package (for cfncluster-awsbatchcli)
  if node['platform_family'] == 'rhel' && node['platform_version'].to_i < 7
    # For CentOS 6 use shell_out function in order to have a correct PATH needed to compile cfncluster dependencies
    ruby_block "pip_install_cfncluster" do
      block do
        pip_install_package('cfncluster', node['cfncluster']['cfncluster-version'])
      end
    end
  else
    python_package "cfncluster" do
      version node['cfncluster']['cfncluster-version']
    end
  end
end