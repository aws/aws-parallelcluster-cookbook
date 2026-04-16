# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: bootstrap_slurm_accounting
#
# Copyright:: 2026 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if kitchen_test? || (node['cluster']['node_type'] == "ExternalSlurmDbd")

execute "wait for cluster registration" do
  # The cluster name used for accounting may differ from the stack name if the user has overridden
  # ClusterName via custom Slurm settings. Read the effective value from the running slurmctld config.
  command lazy {
    cluster_name = get_slurm_accounting_cluster_name
    "#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr show clusters -Pn cluster=#{cluster_name} format=cluster | grep -Fxi '#{cluster_name}'"
  }
  retries 30
  retry_delay 10
end

bash "bootstrap slurm database" do
  user 'root'
  group 'root'
  code lazy {
    cluster_name = get_slurm_accounting_cluster_name
    <<-BOOTSTRAP
    SACCTMGR_CMD=#{node['cluster']['slurm']['install_dir']}/bin/sacctmgr
    CLUSTER_NAME=#{cluster_name}
    DEF_ACCOUNT=pcdefault
    SLURM_USER=#{node['cluster']['slurm']['user']}
    DEF_USER=#{node['cluster']['cluster_user']}

    # Add account-cluster association to database if it is not present yet
    [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT format=account | grep $DEF_ACCOUNT) ]] || \
        $SACCTMGR_CMD -iQ add account $DEF_ACCOUNT Cluster=$CLUSTER_NAME \
            Description="ParallelCluster default account" Organization="none"

    # Add user-account associations to database if they are not present yet
    [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT user=$SLURM_USER format=user | grep $SLURM_USER) ]] || \
        $SACCTMGR_CMD -iQ add user $SLURM_USER Account=$DEF_ACCOUNT AdminLevel=Admin
    [[ $($SACCTMGR_CMD list associations -Pn cluster=$CLUSTER_NAME account=$DEF_ACCOUNT user=$DEF_USER format=user | grep $DEF_USER) ]] || \
        $SACCTMGR_CMD -iQ add user $DEF_USER Account=$DEF_ACCOUNT AdminLevel=Admin

    exit 0
    BOOTSTRAP
  }
end
