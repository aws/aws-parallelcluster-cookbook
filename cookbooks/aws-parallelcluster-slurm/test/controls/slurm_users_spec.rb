# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:config_slurm_plugin_permissions_correctly_defined_on_head_node' do
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' }

  describe file("#{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq node['cluster']['cluster_admin_user'] }
    its('group') { should eq node['cluster']['cluster_admin_user'] }
  end
end

control 'tag:config_slurm_user_and_group_correctly_defined' do
  only_if { node['cluster']['scheduler'] == 'slurm' }

  describe user(node['cluster']['slurm']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['slurm']['user_id'] }
    its('gid') { should eq node['cluster']['slurm']['group_id'] }
    # 'slurm user'
  end

  describe group(node['cluster']['slurm']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['slurm']['group_id'] }
  end
end

control 'tag:config_munge_user_and_group_correctly_defined' do
  only_if { node['cluster']['scheduler'] == 'slurm' && !os_properties.on_docker? }

  describe user(node['cluster']['munge']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['munge']['user_id'] }
    its('gid') { should eq node['cluster']['munge']['group_id'] }
    its('shell') { should eq '/sbin/nologin' }
    # 'munge user'
  end

  describe group(node['cluster']['munge']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['munge']['group_id'] }
  end
end

control 'tag:config_slurm_sudoers_correctly_defined' do
  only_if { node['cluster']['scheduler'] == 'slurm' }

  install_dir = node['cluster']['slurm']['install_dir']
  venv_bin = "#{node['cluster']['node_virtualenv_path']}/bin"
  redhat_on_docker = os_properties.redhat_on_docker?

  describe file("/etc/sudoers.d/99-parallelcluster-slurm") do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match /#{node['cluster']['cluster_admin_user']} ALL = \(root\) NOPASSWD: SLURM_COMMANDS/ }
    its('content') { should match %r{Cmnd_Alias SLURM_COMMANDS = #{install_dir}/bin/scontrol, #{install_dir}/bin/sinfo} }
    its('content') { should match /#{node['cluster']['cluster_admin_user']} ALL = \(root\) NOPASSWD: SHUTDOWN/ }
    its('content') { should match %r{Cmnd_Alias SHUTDOWN = /usr/sbin/shutdown} }
    its('content') { should match /#{node['cluster']['slurm']['user']} ALL = \(#{node['cluster']['cluster_admin_user']}\) NOPASSWD:SETENV: SLURM_HOOKS_COMMANDS/ }
    its('content') { should match %r{Cmnd_Alias SLURM_HOOKS_COMMANDS = #{venv_bin}/slurm_suspend, #{venv_bin}/slurm_resume, #{venv_bin}/slurm_fleet_status_manager} } unless redhat_on_docker
  end
end
