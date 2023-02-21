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

control 'head_node_base_configured' do
  title 'Check the base headnode configuration'

  # Check if authorized_keys_cluster has been created
  # The command checks all the homes with globbing since the user can be different for each OS
  describe command("sudo su -c 'ls /home/*/.ssh/authorized_keys_cluster'") do
    its('exit_status') { should eq 0 }
  end unless os_properties.redhat_ubi?

  describe file('/usr/local/bin/update-compute-fleet-status.sh') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end

  describe file('/usr/local/bin/get-compute-fleet-status.sh') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end

  describe file('/etc/parallelcluster/clusterstatusmgtd.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should match /cluster_name = \w+/ }
    its('content') { should match %r{computefleet_status_path = /opt/parallelcluster/shared/computefleet-status.json\n} }
  end
end
