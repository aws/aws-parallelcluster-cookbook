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
