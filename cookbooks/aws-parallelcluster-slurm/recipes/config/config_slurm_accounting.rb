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
  variables(
    dbd_host: "localhost",
    dbd_port: node['slurmdbd_port'],
    dbd_addr: node['slurmdbd_ip'],
    storage_host: node['dbms_uri'],
    # TODO: expose additional CFN Parameter in template
    storage_port: 3306,
    storage_loc: node['dbms_database_name'],
    storage_user: node['dbms_username']
  )
  only_if { node['is_external_slurmdbd'] }
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

service "slurmdbd" do
  supports restart: false
  action %i(enable start)
end unless on_docker?

# After starting slurmdbd the database may not be fully responsive yet and
# its bootstrapping may fail. We need to wait for sacctmgr to successfully
# query the database before proceeding.
# In case of an external slurmdbd the Slurm commands do not work, so this
# check cannot be executed.
execute "wait for slurm database" do
  command "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn"
  retries node['cluster']['slurmdbd_response_retries']
  retry_delay 10
end unless kitchen_test? || node['is_external_slurmdbd']

bash "bootstrap slurm database" do
  user 'root'
  group 'root'
  code <<-BOOTSTRAP
    SACCTMGR_CMD=#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr
    CLUSTER_NAME=#{node['cluster']['stack_name']}
    DEF_ACCOUNT=pcdefault
    SLURM_USER=#{node['cluster']['slurm']['user']}
    DEF_USER=#{node['cluster']['cluster_user']}

    # Add cluster to database if it is not present yet
    [[ $($SACCTMGR_CMD show clusters -Pn cluster=$CLUSTER_NAME | grep $CLUSTER_NAME) ]] || \
        $SACCTMGR_CMD -iQ add cluster $CLUSTER_NAME

    # Add account-cluster association to database if it is not present yet
    [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT format=account | grep $DEF_ACCOUNT) ]] || \
        $SACCTMGR_CMD -iQ add account $DEF_ACCOUNT Cluster=$CLUSTER_NAME \
            Description="ParallelCluster default account" Organization="none"

    # Add user-account associations to database if they are not present yet
    [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT user=$SLURM_USER format=user | grep $SLURM_USER) ]] || \
        $SACCTMGR_CMD -iQ add user $SLURM_USER Account=$DEF_ACCOUNT AdminLevel=Admin
    [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT user=$DEF_USER format=user | grep $DEF_USER) ]] || \
        $SACCTMGR_CMD -iQ add user $DEF_USER Account=$DEF_ACCOUNT AdminLevel=Admin

    # sacctmgr might throw errors if the DEF_ACCOUNT is not associated to a cluster already defined on the database.
    # This is not important for the scope of this script, so we return 0.
    exit 0
  BOOTSTRAP
end unless kitchen_test? || node['is_external_slurmdbd']
