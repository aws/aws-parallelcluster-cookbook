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
    secret_arn: node['cluster']['slurm']['database']['password_secret_arn'],
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

# After starting slurmdbd the database may not be fully responsive yet and
# its bootstrapping may fail. We need to wait for sacctmgr to successfully
# query the database before proceeding.
bash "wait for slurm database" do
  user 'root'
  group 'root'
  code <<-WAIT
    SACCTMGR_CMD=#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr
    RETRY_DELAY=5
    MAX_RETRIES=6

    rc=1
    retry=0
    while [ $rc -ne 0 ]; do
        if [ $retry -eq $MAX_RETRIES ]; then break; fi
        sleep $RETRY_DELAY
        $SACCTMGR_CMD show clusters -Pn
        rc=$?
        retry=$(( $retry + 1 ))
    done
    exit $rc
  WAIT
end

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
end

