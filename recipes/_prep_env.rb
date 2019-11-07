# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _prep_env
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Determine cfn_scheduler_slots settings and update cfn_instance_slots appropriately
node.default['cfncluster']['cfn_instance_slots'] = if node['cfncluster']['cfn_scheduler_slots'] == 'vcpus'
                                                     node['cpu']['total']
                                                   elsif node['cfncluster']['cfn_scheduler_slots'] == 'cores'
                                                     node['cpu']['total'].fdiv(2).ceil
                                                   else
                                                     node['cfncluster']['cfn_scheduler_slots']
                                                   end

directory '/etc/parallelcluster'
directory '/opt/parallelcluster'
directory '/opt/parallelcluster/scripts'

# Create ParallelCluster log folder
directory '/var/log/parallelcluster/' do
  owner 'root'
  mode '1777'
  recursive true
end

template '/etc/parallelcluster/cfnconfig' do
  source 'cfnconfig.erb'
  mode '0644'
end

link '/opt/parallelcluster/cfnconfig' do
  to '/etc/parallelcluster/cfnconfig'
end

template "/opt/parallelcluster/scripts/fetch_and_run" do
  source 'fetch_and_run.erb'
  owner "root"
  group "root"
  mode "0755"
end

template '/opt/parallelcluster/scripts/compute_ready' do
  source 'compute_ready.erb'
  owner "root"
  group "root"
  mode "0755"
end
