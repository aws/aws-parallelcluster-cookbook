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

control 'mount_home_efs' do
  title 'Check if the home directory in mounted'

  only_if { !os_properties.on_docker? }

  describe mount('/home') do
    it { should be_mounted }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'rw' }
  end
end

control 'mount_shared_compute_efs' do
  title 'Check if the shared directory is mounted'

  only_if { !os_properties.on_docker? && (instance.compute_node? or instance.head_node?) }

  describe mount('/opt/parallelcluster/shared') do
    it { should be_mounted }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'rw' }
  end

  if instance.compute_node?
    describe mount('/opt/parallelcluster/shared_login_nodes') do
      it { should_not be_mounted }
    end
  end
end

control 'mount_shared_login_efs' do
  title 'Check if the shared directory is mounted'

  only_if { !os_properties.on_docker? && (instance.login_node? or instance.head_node?) }

  describe mount('/opt/parallelcluster/shared_login_nodes') do
    it { should be_mounted }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'rw' }
  end

  if instance.login_node?
    describe mount('/opt/parallelcluster/shared') do
      it { should_not be_mounted }
    end
  end
end

control 'mount_intel_efs' do
  title 'Check the shared intel dir is available'

  only_if { !os_properties.on_docker? }

  describe 'Check that /opt/intel dir has been mounted'
  describe mount("/opt/intel") do
    it { should be_mounted }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'hard' }
    its('options') { should include '_netdev' }
  end

  describe directory("/opt/intel/mpi") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end

control 'mount_slurm_efs' do
  title 'Check the shared slurm dir is available'

  only_if { !os_properties.on_docker? }

  describe 'Check that /opt/intel dir has been mounted'
  describe mount("/opt/slurm") do
    it { should be_mounted }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'hard' }
    its('options') { should include '_netdev' }
  end

  describe directory("/opt/slurm/bin") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end
end
