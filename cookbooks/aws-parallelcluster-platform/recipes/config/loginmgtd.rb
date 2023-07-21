# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: loginmgtd.rb
#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

load_cluster_config(node['cluster']['login_cluster_config_path'])

# Create the configuration file for loginmgtd
template "#{node['cluster']['shared_dir_login_nodes']}/loginmgtd_config.json" do
  source 'loginmgtd/loginmgtd_config.json.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_user']
  mode '0644'
  variables(
    gracetime_period: lazy { node['cluster']['config'].dig(:LoginNodes, :Pools, 0, :GracetimePeriod) }
  )
end

# Create the termination hook for loginmgtd
template "#{node['cluster']['shared_dir_login_nodes']}/loginmgtd_on_termination.sh" do
  source 'loginmgtd/loginmgtd_on_termination.sh.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_user']
  mode '0744'
end

# Create the script to run loginmgtd
template "#{node['cluster']['shared_dir_login_nodes']}/loginmgtd.sh" do
  source 'loginmgtd/loginmgtd.sh.erb'
  owner node['cluster']['cluster_admin_user']
  group node['cluster']['cluster_admin_user']
  mode '0744'
end

# Create sudoers entry to let pcluster-admin user execute loginmgtd privileged actions
template '/etc/sudoers.d/99-parallelcluster-loginmgtd' do
  source 'loginmgtd/99-parallelcluster-loginmgtd.erb'
  owner 'root'
  group 'root'
  mode '0600'
end
