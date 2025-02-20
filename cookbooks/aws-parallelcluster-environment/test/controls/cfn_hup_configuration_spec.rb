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

control 'tag:config_cfn_hup_conf_files_created' do
  title "cfn_hup configuration files and directories should be created"

  %w(/etc/cfn /etc/cfn/hooks.d).each do |dir|
    describe directory(dir) do
      it { should exist }
      its('mode') { should cmp '0700' }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
    end
  end

  %w(/etc/cfn/cfn-hup.conf /etc/cfn/hooks.d/pcluster-update.conf).each do |conf_file|
    describe file(conf_file) do
      it { should exist }
      its('mode') { should cmp '0400' }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
    end
  end
end

control 'tag:config_cfn_hup_head_node_configuration' do
  title "cfn_hup configuration files and directories for HeadNode should be created"
  only_if { instance.head_node? }

  describe file("#{node['cluster']['scripts_dir']}/share_compute_fleet_dna.py") do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe directory("#{node['cluster']['shared_dir']}/dna") do
    it { should exist }
  end
end

control 'tag:config_cfn_hup_compute_configuration' do
  title "cfn_hup configuration files and directories for ComputeFleet should be created"
  only_if { instance.compute_node? }

  describe file("#{node['cluster']['scripts_dir']}/cfn-hup-update-action.sh") do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end
