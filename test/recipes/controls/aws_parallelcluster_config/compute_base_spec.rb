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

control 'compute_base_configured' do
  title 'Check the basic configuration for compute node'

  only_if { !os_properties.virtualized? }

  describe 'Check that cluster user exist'
  describe user('test_user') do
    it { should exist }
    its('home') { should eq '/home/test_user' }
    its('shell') { should eq '/bin/bash' }
  end

  describe 'Check that raid and ebs dirs have been created and mounted'
  directories = %w(raid1 ebs1 ebs2)
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
      its('device') { should eq "127.0.0.1:/exported_#{directory}" }
      its('type') { should eq 'nfs4' }
      its('options') { should include 'hard' }
      its('options') { should include '_netdev' }
      its('options') { should include 'noatime' }
    end
  end

  describe 'Check that /opt/intel dir has been mounted'
  describe mount("/opt/intel") do
    it { should be_mounted }
    its('device') { should eq "127.0.0.1:/exported_intel" }
    its('type') { should eq 'nfs4' }
    its('options') { should include 'hard' }
    its('options') { should include '_netdev' }
    its('options') { should include 'noatime' }
  end
end
