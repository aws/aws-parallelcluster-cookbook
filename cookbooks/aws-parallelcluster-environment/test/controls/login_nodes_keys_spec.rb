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

key_types = %w(ecdsa ed25519 rsa)
is_ubuntu = os_properties.ubuntu?
if is_ubuntu
  key_types << 'dsa'
end

control 'head_node_directory_initialized' do
  only_if { instance.head_node? && node['cluster']['scheduler'] != 'awsbatch' }
  describe directory("#{node['cluster']['shared_dir_login_nodes']}/scripts") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0744' }
  end

  key_types.each do |type|
    describe file('/opt/parallelcluster/shared_login_nodes/ssh_host_' + type + '_key') do
      it { should exist }
      its('content') { should_not be_empty }
    end

    describe file('/opt/parallelcluster/shared_login_nodes/ssh_host_' + type + '_key.pub') do
      it { should exist }
      its('content') { should_not be_empty }
    end
  end
end

control 'login_node_configuration_initialized' do
  only_if { instance.login_node? && node['cluster']['scheduler'] != 'awsbatch' }

  key_types.each do |type|
    describe file('/etc/ssh/ssh_host_' + type + '_key') do
      it { should exist }
      its('owner') { should eq 'root' }
      if is_ubuntu
        its('mode') { should cmp '0600' }
        its('group') { should eq 'root' }
      else
        its('mode') { should cmp '0640' }
        its('group') { should eq 'ssh_keys' }
      end
      its('content') { should_not be_empty }
    end

    describe file('/etc/ssh/ssh_host_' + type + '_key.pub') do
      it { should exist }
      its('mode') { should cmp '0644' }
      its('owner') { should eq 'root' }
      if is_ubuntu
        its('group') { should eq 'root' }
      else
        its('group') { should eq 'ssh_keys' }
      end
      its('content') { should_not be_empty }
    end
  end
end
