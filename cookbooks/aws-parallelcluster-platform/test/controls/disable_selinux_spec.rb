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

# SELinux exists only on RHEL-family OSes. Skip Docker because the test
# container has no real kernel cmdline and grubby is not installed.
selinux_applies = (os_properties.alinux2023? || os_properties.redhat? || os_properties.rocky?) && !os_properties.on_docker?

control 'tag:install_selinux_disabled' do
  title 'Check if selinux is disabled'
  describe selinux do
    it { should be_disabled }
    it { should_not be_enforcing }
  end unless os_properties.alinux2023? || os_properties.redhat? || os_properties.rocky? # Because it requires reboot of the instance

  # Verify selinux=0 is configured (and selinux=1 removed) in the bootloader
  # before reboot — works on kernels >= 6.4 where /etc/selinux/config is ignored.
  describe command('grubby --info=ALL') do
    its('stdout') { should match(/selinux=0/) }
    its('stdout') { should_not match(/selinux=1/) }
  end if selinux_applies
end

control 'tag:testami_selinux_disabled' do
  title 'Check if selinux is disabled'

  describe selinux do
    it { should be_disabled }
    it { should_not be_enforcing }
  end if selinux_applies

  # After reboot, verify the active kernel cmdline. Catches the "half-disabled"
  # state where /etc/selinux/config says disabled but the kernel ignored it.
  describe file('/proc/cmdline') do
    its('content') { should match(/selinux=0/) }
    its('content') { should_not match(/selinux=1/) }
  end if selinux_applies
end
