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

control 'tag:install_clusterstatusmgtd_files_created' do
  title 'clusterstatusmgtd script and logging config are copied to the target dir'

  describe file('/opt/parallelcluster/scripts/clusterstatusmgtd.py') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end

  describe file('/opt/parallelcluster/scripts/clusterstatusmgtd_logging.conf') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end
end

control 'tag:config_clusterstatusmgtd' do
  title 'Check the creation of clusterstatusmgtd files'

  only_if { instance.head_node? && node['cluster']['scheduler'] == 'slurm' }

  describe file('/opt/parallelcluster/shared/computefleet-status.json') do
    it { should exist }
    its('content') { should_not match /^""$/ }
    its('owner') { should eq 'pcluster-admin' }
    its('group') { should eq 'pcluster-admin' }
    its('mode') { should cmp '0755' }
  end

  describe file('/etc/sudoers.d/99-parallelcluster-clusterstatusmgtd') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
    its('content') { should match %r{Cmnd_Alias CINC_COMMAND = /usr/bin/cinc-client .*\n\npcluster-admin ALL = \(root\) NOPASSWD: CINC_COMMAND.*} }
  end

  describe file('/var/log/parallelcluster/clusterstatusmgtd') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0640' }
  end
end
