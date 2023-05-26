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

control 'tag:install_expected_versions_of_nvidia_fabric_manager_installed' do
  only_if { !os_properties.arm? && ['yes', true].include?(node['cluster']['nvidia']['enabled']) }

  describe package(node['cluster']['nvidia']['fabricmanager']['package']) do
    it { should be_installed }
    its('version') { should match /#{node['cluster']['nvidia']['fabricmanager']['version']}/ }
  end

  version_lock_check = os_properties.debian_family? ? 'apt-mark showhold | grep "nvidia-fabric.*manager"' : 'yum versionlock list | grep "nvidia-fabric.*manager"'
  describe bash(version_lock_check) do
    its('exit_status') { should eq 0 }
  end
end

control 'tag:config_nvidia_fabric_manager_enabled' do
  only_if { instance.nvs_switch_enabled? }

  describe service('nvidia-fabricmanager') do
    it { should be_enabled }
    it { should be_running }
  end
end
