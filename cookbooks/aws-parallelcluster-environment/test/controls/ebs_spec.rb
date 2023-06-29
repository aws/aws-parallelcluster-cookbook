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

control 'ebs_mounted' do
  only_if { !os_properties.on_docker? }
  describe mount('/shared_dir') do
    it { should be_mounted }
    its('device') { should eq '/dev/xvdb' }
    its('type') { should eq 'ext4' }
    its('options') { should include '_netdev' }
  end

  describe 'Verify EBS is correctly mounted'

  # List mounted folders and verify the EBS shared dir is in the output
  # $ df -h -t ext4
  # Filesystem      Size  Used Avail Use% Mounted on
  # /dev/xvdb        976M  2.6M  923M   1% /shared_dir
  describe bash("df -h -t ext4 | tail -n +2 | awk '{{print $2, $6}}' | grep '/shared_dir'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('976M /shared_dir') }
  end

  describe bash("cat /etc/fstab") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('UUID=.* /shared_dir ext4 _netdev 0 0') }
  end
end

control 'ebs_unmounted' do
  only_if { !os_properties.on_docker? }

  describe mount('/shared_dir') do
    it { should_not be_mounted }
  end
end

control 'ebs_exported' do
  only_if { !os_properties.on_docker? }

  describe bash('cat /etc/exports') do
    its('exit_status') { should eq(0) }
    its('stdout') { should match %r{^/shared_dir } }
  end
end

control 'ebs_unexported' do
  only_if { !os_properties.on_docker? }

  describe bash('cat /etc/exports') do
    its('exit_status') { should eq(0) }
    its('stdout') { should_not match %r{^/shared_dir } }
  end
end

control 'ebs_compute' do
  title 'Check the ebs configuration for compute node'

  only_if { !os_properties.on_docker? && instance.compute_node? }

  describe 'Check that ebs dirs have been created and mounted'
  directories = %w(ebs1 ebs2)
  directories.each do |directory|
    describe directory("/#{directory}") do
      it { should exist }
      it { should be_mounted }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '01777' }
    end

    describe mount("/#{directory}") do
      it { should be_mounted }
      its('device') { should eq "127.0.0.1:/#{directory}" }
      its('type') { should eq 'nfs4' }
      its('options') { should include 'hard' }
      its('options') { should include '_netdev' }
      its('options') { should include 'noatime' }
    end
  end
end
