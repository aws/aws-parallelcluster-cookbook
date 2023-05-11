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

control 'nfs_configured' do
  title 'Check that nfs is configured correctly'

  only_if { !os_properties.virtualized? }

  describe 'Check nfs service is restarted'
  nfs_server = os.debian? ? 'nfs-kernel-server.service' : 'nfs-server.service'
  describe service(nfs_server) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe 'Check that the number of nfs threads is correct'
  describe bash("grep th /proc/net/rpc/nfsd | awk '{print $2}'") do
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp 10 }
  end
end

control 'tag:config_nfs_correctly_installed_on_head_node' do
  only_if { instance.head_node? && !os_properties.on_docker? }

  describe 'check for nfs server protocol' do
    subject { command "sudo -u #{node['cluster']['cluster_user']} rpcinfo -p localhost | awk '{print $2$5}' | grep 4nfs" }
    its('exit_status') { should eq 0 }
  end
end

control 'tag:config_nfs_correctly_installed_on_compute_node' do
  only_if { instance.compute_node? && !os_properties.on_docker? }

  describe 'check for nfs server protocol' do
    subject { command "sudo -u #{node['cluster']['cluster_user']} nfsstat -m | grep vers=4" }
    its('exit_status') { should eq 0 }
  end
end

control 'tag:config_nfs_has_correct_number_of_threads' do
  only_if { !os_properties.on_docker? }

  describe bash("cat /proc/net/rpc/nfsd | grep th | awk '{print$2}'") do
    its('stdout') { should cmp node['cluster']['nfs']['threads'] }
  end
end
