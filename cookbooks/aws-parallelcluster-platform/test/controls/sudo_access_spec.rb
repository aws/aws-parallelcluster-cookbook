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

control 'tag:config_sudo_access_disable_action' do
  title 'Check if sudo access for default user is disabled'
  only_if { node['cluster']["disable_sudo_access_for_default_user"] == 'true' }

  describe file('/etc/sudoers') do
    it { should exist }
    its('content') { should_not match /\b\S*(#{node['cluster']['cluster_user']} ALL=(ALL) NOPASSWD:ALL)/ }
  end

  describe file('/etc/sudoers.d/99-parallelcluster-revoke-sudo-access') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
    its('content') { should match "#{node['cluster']['cluster_user']} ALL=(ALL) !ALL\n" }
  end

  describe bash("sudo -l -U #{node['cluster']['cluster_user']} | tail -1 | awk '{$1=$1};1'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match "(ALL) !ALL\n" }
  end unless os_properties.on_docker?
end

control 'tag:config_sudo_access_enabled_action' do
  title 'Check if sudo access for default user is enabled'
  only_if { [ 'false', nil].include?(node['cluster']["disable_sudo_access_for_default_user"]) }

  describe file('/etc/sudoers.d/99-parallelcluster-revoke-sudo-access') do
    it { should_not exist }
  end

  describe file('/etc/sudoers.d/90-cloud-init-users') do
    it { should exist }
    its('content') { should match /^[\-#\.,\:\+\w\s]*(rocky ALL=\(ALL\) NOPASSWD:ALL)/ }
  end unless os_properties.on_docker?

  describe bash("sudo -l -U #{node['cluster']['cluster_user']} | tail -1 | awk '{$1=$1};1'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match "(ALL) NOPASSWD: ALL\n" }
  end unless os_properties.on_docker?
end
