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

control 'tag:config_slurm_correctly_installed_on_head_node' do
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' && !os_properties.on_docker? }

  describe service('slurmctld') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe bash("#{node['cluster']['slurm']['install_dir']}/bin/sinfo --help") do
    its('exit_status') { should eq 0 }
  end

  describe bash("#{node['cluster']['slurm']['install_dir']}/bin/scontrol --help") do
    its('exit_status') { should eq 0 }
  end

  describe bash("ls #{node['cluster']['slurm']['install_dir']}/lib/slurm/") do
    its('stdout') { should match /accounting_storage_mysql/ }
    its('stdout') { should match /jobcomp_mysql/ }
    its('stdout') { should match /pmix/ }
  end

  describe 'pmix shared library can be found' do
    subject { bash('/opt/pmix/bin/pmix_info') }
    its('exit_status') { should eq 0 }
  end
end

control 'tag:config_slurm_correctly_installed_on_compute_node' do
  only_if { instance.compute_node? && node['cluster']['scheduler'] == 'slurm' }

  describe bash("sudo -u #{node['cluster']['cluster_user']} ls #{node['cluster']['slurm']['install_dir']}") do
    its('exit_status') { should eq 0 }
  end

  describe 'check cgroup memory resource controller is enabled' do
    # Check if we're using cgroups v2
    cgroup_v2 = bash('test -f /sys/fs/cgroup/cgroup.controllers').exit_status == 0

    if cgroup_v2
      # For cgroups v2, check if memory controller is in available controllers
      describe bash('cat /sys/fs/cgroup/cgroup.controllers') do
        its('stdout') { should include 'memory' }
        its('exit_status') { should eq 0 }
      end
    else
      # Original check for cgroups v1
      describe bash("grep memory /proc/cgroups | awk '{print $4}'") do
        its('stdout.strip') { should cmp '1' }
        its('exit_status') { should eq 0 }
      end
    end
  end
end
