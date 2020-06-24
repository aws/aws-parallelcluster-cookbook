# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _compute_slurm_finalize
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
    # Retrieve private ip from Metadata V2
    require 'mixlib/shellout'
    node.run_state['compute_ip'] = shell_out!('curl http://169.254.169.254/latest/meta-data/local-ipv4', :user => 'root').stdout.strip
    # Retrieve NodeName from scontrol
    node.run_state['slurm_compute_nodename'] = shell_out!("/opt/slurm/bin/scontrol show nodes | awk \"/\\y#{node.run_state['compute_ip']}\\y/\" RS= | grep -oP '^NodeName=\\K(\\S+)'", :user => 'root').stdout.strip
  end
  retries 3
  retry_delay 5
end

directory '/etc/sysconfig' do
  user 'root'
  group 'root'
  mode '0644'
end

if node['init_package'] == 'systemd'
  file '/etc/sysconfig/slurmd' do
    content(lazy { "SLURMD_OPTIONS='-N #{node.run_state['slurm_compute_nodename']}'" })
    mode '0644'
    owner 'root'
    group 'root'
  end

  service "slurmd" do
    supports restart: false
    action %i[enable start]
  end
else
  file '/etc/sysconfig/slurm' do
    content(lazy { "SLURMD_OPTIONS='-N #{node.run_state['slurm_compute_nodename']}'" })
    mode '0644'
    owner 'root'
    group 'root'
  end

  service "slurm" do
    supports restart: false
    action %i[enable start]
  end
end
