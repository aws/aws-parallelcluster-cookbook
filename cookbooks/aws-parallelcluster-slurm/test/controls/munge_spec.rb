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

munge_user = 'munge'
munge_group = munge_user

control 'tag:install_munge_installed' do
  title "Munge is downloaded and installed"
  describe file('/usr/sbin/munged') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end unless os_properties.redhat_on_docker?

control 'tag:install_munge_user_and_group_created' do
  title 'Check munge user and group exist and are properly configured'

  describe group(munge_group) do
    it { should exist }
  end

  describe user(munge_user) do
    it { should exist }
    its('group') { should eq munge_group }
  end
end unless os_properties.redhat_on_docker?

control 'tag:install_munge_folders_created' do
  title 'Munge folder have been created'

  describe file('/var/log/munge') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/etc/munge') do
    it { should exist }
    it { should be_directory }
  end

  describe file('/var/run/munge') do
    it { should exist }
    it { should be_directory }
  end
end unless os_properties.redhat_on_docker?

control 'tag:config_munge_service_enabled' do
  only_if { node['cluster']['scheduler'] == 'slurm' && !os_properties.redhat_on_docker? }

  describe service('munge') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'tag:config_munge_check_munge_key_exists' do
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' && !os_properties.redhat_on_docker? }

  title 'Check if the munge key exists'
  describe file('/etc/munge/munge.key') do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('owner') { should eq node['cluster']['munge']['user'] }
    its('group') { should eq node['cluster']['munge']['group'] }
  end
end

control 'tag:config_munge_check_munge_key_content' do
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' && !os_properties.redhat_on_docker? }

  title 'Check if the munge key content is not empty'
  describe file('/etc/munge/munge.key') do
    its('content') { should_not be_empty }
  end
end

control 'tag:config_munge_check_munge_key_error_messages' do
  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' && !os_properties.redhat_on_docker? }

  title 'Check for error messages related to munge key'
  describe file('/var/log/chef-client.log') do
    its('content') { should_not match /Error fetching munge key/ }
    its('content') { should_not match /Error decoding the munge key/ }
  end
end
