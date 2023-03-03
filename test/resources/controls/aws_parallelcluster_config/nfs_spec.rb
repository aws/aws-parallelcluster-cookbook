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
