#
# Cookbook Name:: cfncluster
# Recipe:: slurm_config
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

include_recipe 'cfncluster::base_config'
include_recipe 'cfncluster::slurm_install'

# Create the munge key from template
template "/etc/munge/munge.key" do
  source "munge.key.erb"
  owner "munge"
  mode "0600"
end

# Enable munge service
service "munge" do
  supports restart: true
  action %i[enable start]
end

cookbook_file '/etc/init.d/slurm' do
  source 'slurm-init'
  owner 'root'
  group 'root'
  mode '0755'
end

# case node['cfncluster']['cfn_node_type']
case node['cfncluster']['cfn_node_type']
when 'MasterServer'
  include_recipe 'cfncluster::_master_slurm_config'
when 'ComputeFleet'
  include_recipe 'cfncluster::_compute_slurm_config'
else
  raise "cfn_node_type must be MasterServer or ComputeFleet"
end

link '/etc/profile.d/slurm.sh' do
  to '/opt/slurm/etc/slurm.sh'
end

link '/etc/profile.d/slurm.csh' do
  to '/opt/slurm/etc/slurm.csh'
end
