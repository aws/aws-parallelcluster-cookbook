# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: config_head_node
#
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

template '/etc/systemd/system/slurmdbd.service' do
  source 'slurm/head_node/slurmdbd.service.erb'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

template "#{node['cluster']['slurm']['install_dir']}/etc/slurmdbd.conf" do
  source 'slurm/slurmdbd.conf.erb'
  owner "#{node['cluster']['slurm']['user']}"
  group "#{node['cluster']['slurm']['group']}"
  mode '0600'
  # Do not overwrite possible user customization if the database credentials are updated
  action :create_if_missing
end

template "#{node['cluster']['slurm']['install_dir']}/etc/slurm_external_slurmdbd.conf" do
  source 'slurm/external_slurmdbd/slurm_external_slurmdbd.conf.erb'
  owner "#{node['cluster']['slurm']['user']}"
  group "#{node['cluster']['slurm']['group']}"
  mode '0600'
  action :create_if_missing
  only_if { node['cluster']['node_type'] == "ExternalSlurmDbd" }
end

file "#{node['cluster']['slurm']['install_dir']}/etc/slurm_parallelcluster_slurmdbd.conf" do
  owner "#{node['cluster']['slurm']['user']}"
  group "#{node['cluster']['slurm']['group']}"
  mode '0600'
end

template "#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh" do
  source 'slurm/head_node/update_slurm_database_password.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    secret_arn: lazy { node['dbms_password_secret_arn'] || node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :Database, :PasswordSecretArn) },
    region: node['cluster']['region'],
    slurm_install_dir: node['cluster']['slurm']['install_dir']
  )
  sensitive true
end

execute "update Slurm database password" do
  user 'root'
  group 'root'
  command "#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh"
end unless kitchen_test?

action = if node['cluster']['slurmdbd_service_enabled'] == "true"
           %i(enable start)
         else
           %i(disable)
         end
service "slurmdbd" do
  supports restart: false
  action action
end unless on_docker?

if node['cluster']['slurmdbd_service_enabled'] == "true"
  # After starting slurmdbd the database may not be fully responsive yet and
  # its bootstrapping may fail. We need to wait for sacctmgr to successfully
  # query the database before proceeding.
  # In case of an external slurmdbd the Slurm commands do not work, so this
  # check cannot be executed.
  execute "wait for slurm database" do
    command "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn"
    retries node['cluster']['slurmdbd_response_retries']
    retry_delay 10
  end unless kitchen_test? || (node['cluster']['node_type'] == "ExternalSlurmDbd")
end
