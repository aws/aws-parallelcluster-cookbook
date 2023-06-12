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

control 'tag:install_raid' do
  only_if { !os_properties.redhat_ubi? }
  describe package('mdadm') do
    it { should be_installed }
  end
end

control 'raid_mounted' do
  only_if { !os_properties.on_docker? }
  describe mount('/shared_dir') do
    it { should be_mounted }
    its('device') { should eq '/dev/md0' }
    its('type') { should eq 'ext4' }
    its('options') { should include '_netdev' }
  end

  describe 'Verify RAID is correctly configured'
  describe bash("sudo mdadm --detail /dev/md0") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Raid Level : raid1') }
    its('stdout')      { should match('Raid Devices : 2') }
    its('stdout')      { should match('Active Devices : 2') }
    its('stdout')      { should match('Failed Devices : 0') }
    its('stdout')      { should match('Array Size : .*\((.*) MiB') }
  end

  describe 'Ensure that the RAID array is reassembled automatically on boot'
  describe bash("sudo cat /etc/mdadm.conf || sudo cat /etc/mdadm/mdadm.conf | grep $(sudo mdadm --detail --scan)") do
    its('exit_status') { should eq(0) }
  end

  describe 'Verify RAID is correctly mounted'

  # List mounted folders and verify the RAID shared dir is in the output
  # $ df -h -t ext4
  # Filesystem      Size  Used Avail Use% Mounted on
  # /dev/md0        992M  2.6M  923M   1% /shared_dir
  describe bash("df -h -t ext4 | tail -n +2 | awk '{{print $2, $6}}' | grep '/shared_dir'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('992M /shared_dir') }
  end

  describe bash("cat /etc/fstab") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('/dev/md0 /shared_dir ext4 defaults,nofail,_netdev 0 0') }
  end
end

control 'raid_unmounted' do
  only_if { !os_properties.on_docker? }

  describe mount('/shared_dir') do
    it { should_not be_mounted }
  end
end

control 'raid_exported' do
  only_if { !os_properties.on_docker? }

  describe bash('cat /etc/exports') do
    its('exit_status') { should eq(0) }
    its('stdout') { should match %r{^/shared_dir } }
  end
end

control 'raid_unexported' do
  only_if { !os_properties.on_docker? }

  describe bash('cat /etc/exports') do
    its('exit_status') { should eq(0) }
    its('stdout') { should_not match %r{^/shared_dir } }
  end
end
