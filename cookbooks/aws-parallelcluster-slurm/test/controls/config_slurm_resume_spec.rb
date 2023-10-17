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

control 'config_slurm_resume' do
  title 'Check slurm_resume program configuration is created'

  only_if { !(instance.compute_node? or instance.login_node?) }

  describe file('/etc/parallelcluster/slurm_plugin/parallelcluster_slurm_resume.conf') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'pcluster-admin' }
    its('group') { should eq 'pcluster-admin' }
    its('content') { should match 'scaling_strategy = test-strategy' }
  end

  describe file('/opt/parallelcluster/scripts/slurm/slurm_resume') do
    it { should exist }
    its('mode') { should cmp '0744' }
    its('owner') { should eq 'slurm' }
    its('group') { should eq 'slurm' }
  end

  describe file('/var/log/parallelcluster/slurm_resume.events') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'pcluster-admin' }
    its('group') { should eq 'pcluster-admin' }
  end

  describe file('/var/log/parallelcluster/slurm_resume.log') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'pcluster-admin' }
    its('group') { should eq 'pcluster-admin' }
  end
end
