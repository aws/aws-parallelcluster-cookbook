# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_head_node
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

file "#{node['cluster']['slurm']['install_dir']}/etc/slurm_parallelcluster_slurmdbd.conf" do
  owner "#{node['cluster']['slurm']['dbduser']}"
  group "#{node['cluster']['slurm']['dbdgroup']}"
  mode '0600'
end

template "#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh" do
  source 'slurm/head_node/update_slurm_database_password.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    secret_arn: node['cluster']['slurm_database']['password_secret_arn'],
    region: node['cluster']['region'],
    )
  sensitive true
end

execute "update Slurm database password" do
  user 'root'
  group 'root'
  command "#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh"
end

service "slurmdbd" do
  supports restart: false
  action %i(enable start)
end

bash "bootstrap slurm database" do
  user 'root'
  group 'root'
  code <<-BOOTSTRAP
    sleep 10
    #{node['cluster']['slurm']['install_dir']}/bin/sacctmgr -iQ add cluster #{node['cluster']['stack_name']}
    #{node['cluster']['slurm']['install_dir']}/bin/sacctmgr -iQ add account pcdefault Cluster=#{node['cluster']['stack_name']} \
        Description="ParallelCluster default account" Organization="none"
    #{node['cluster']['slurm']['install_dir']}/bin/sacctmgr -iQ add user #{node['cluster']['slurm']['user']} Account=pcdefault AdminLevel=Admin
    #{node['cluster']['slurm']['install_dir']}/bin/sacctmgr -iQ add user #{node['cluster']['cluster_user']} Account=pcdefault AdminLevel=Admin
  BOOTSTRAP
end

