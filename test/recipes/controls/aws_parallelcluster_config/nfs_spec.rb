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

control 'nfs_thread_configured' do
  title 'Check that shared storage info are added correctly to the data file'

  nfs_config_file = if os_properties.centos? || os_properties.alinux2?
                      '/etc/sysconfig/nfs'
                    elsif os.debian?
                      '/etc/default/nfs-kernel-server'
                    else
                      '/etc/nfs.conf'
                    end

  describe file(nfs_config_file) do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match /^RPCNFSDCOUNT="10"/ }
  end
end

control 'nfs_service_restarted' do
  title 'Check nfs service is restarted'

  only_if { !os_properties.virtualized? }

  nfs_server = if os.debian?
                 'nfs-kernel-server.service'
               else
                 'nfs-server.service'
               end

  describe service(nfs_server) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
