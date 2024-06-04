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

control 'tag:install_openssh_installed' do
  title 'Check that openssh packages are installed and ssh/sshd config file exist'
  only_if { !os_properties.alinux2023_on_docker? }

  files = %w(/etc/ssh/ssh_config)
  files.each do |file|
    describe file(file) do
      it { should exist }
      its('mode') { should cmp '0644' }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
    end
  end

  files = %w(/etc/ssh/sshd_config /etc/ssh/ca_keys /etc/ssh/revoked_keys)
  file_permission = if os.debian?
                      '0644'
                    else
                      '0600'
                    end
  files.each do |file|
    describe file(file) do
      it { should exist }
      its('mode') { should cmp file_permission }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
    end
  end

  describe package('openssh-server') do
    it { should be_installed }
  end
end
