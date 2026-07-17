# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:install_expected_versions_of_nvidia_imex_installed' do
  only_if { ['yes', true, 'true'].include?(node['cluster']['nvidia']['enabled']) }

  nvidia_imex_service = 'nvidia-imex'
  ["/usr/bin/#{nvidia_imex_service}", "/usr/bin/#{nvidia_imex_service}-ctl"].each do |path|
    describe file(path) do
      it { should exist }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '0755' }
    end
  end

  describe package("#{node['cluster']['nvidia']['imex']['package']}") do
    it { should be_installed }
    its('version') { should match /#{node['cluster']['nvidia']['imex']['version']}/ }
  end
end

control 'tag:config_nvidia_fabric_manager_enabled' do
  only_if { instance.nvs_switch_enabled? && node['cluster']['node_type'] == "ComputeFleet" }

  describe file("/etc/systemd/system/nvidia-imex.service") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should match %r{ExecStart=/usr/bin/nvidia-imex -c /etc/nvidia-imex/config.cfg} }
  end

  describe service('nvidia-imex') do
    it { should be_enabled }
    it { should be_running }
  end
end
