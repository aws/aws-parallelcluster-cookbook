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

control 'slurm_accounting_configured' do
  title 'Create Slurm database main configuration file'

  only_if { instance.head_node? }

  describe file("#{node['cluster']['slurm']['install_dir']}/etc/slurmdbd.conf") do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('owner') { should eq node['cluster']['slurm']['user'] }
    its('group') { should eq node['cluster']['slurm']['group'] }
  end

  describe file("#{node['cluster']['slurm']['install_dir']}/etc/slurm_parallelcluster_slurmdbd.conf") do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('owner') { should eq node['cluster']['slurm']['user'] }
    its('group') { should eq node['cluster']['slurm']['group'] }
  end

  describe file("#{node['cluster']['scripts_dir']}/slurm/update_slurm_database_password.sh") do
    it { should exist }
    its('mode') { should cmp '0700' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end
