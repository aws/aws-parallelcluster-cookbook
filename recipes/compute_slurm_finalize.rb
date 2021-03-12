# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: compute_slurm_finalize
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

ruby_block 'get_compute_nodename' do
  block do
    node.run_state['slurm_compute_nodename'] = hit_slurm_nodename
  end
end

directory '/etc/sysconfig' do
  user 'root'
  group 'root'
  mode '0644'
end

slurm_service_binary = if node['init_package'] == 'systemd'
                         "slurmd"
                       else
                         "slurm"
                       end

template "/etc/sysconfig/#{slurm_service_binary}" do
  source 'slurm/slurm.sysconfig.erb'
  user 'root'
  group 'root'
  mode '0644'
end

service slurm_service_binary do
  supports restart: false
  action %i[enable start]
  not_if { node['kitchen'] }
end

execute 'resume_node' do
  # Always try to resume a static node on start up
  # Command will fail if node is already in IDLE, ignoring failure
  command(lazy { "/opt/slurm/bin/scontrol update nodename=#{node.run_state['slurm_compute_nodename']} state=resume reason='Node start up'" })
  ignore_failure true
  # Only resume static nodes
  only_if { hit_is_static_node?(node.run_state['slurm_compute_nodename']) }
end
