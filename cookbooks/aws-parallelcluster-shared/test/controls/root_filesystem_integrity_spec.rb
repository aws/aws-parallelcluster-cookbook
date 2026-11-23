# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

# Errors returned when reading corrupted filesystem metadata:
# EBADMSG (ext4 checksum mismatch), EIO, EUCLEAN (ext4/xfs "Structure needs cleaning").
fs_read_errors = %r{Bad message|Input/output error|Structure needs cleaning}

# Kernel messages logged when the root volume or its filesystem is damaged.
kernel_fs_errors = %r{EXT4-fs error|EXT4-fs \(.*\): Remounting filesystem read-only|XFS \(.*\): (Corruption|Metadata corruption|metadata I/O error)|Buffer I/O error|blk_update_request: I/O error|I/O error, dev nvme}

control 'tag:config_root_filesystem_integrity' do
  title 'The whole root filesystem is readable and the kernel reports no filesystem or I/O errors'

  only_if { !os_properties.on_docker? }

  # Entries removed while walking (e.g. temporary files) print "No such file or directory": only read errors matter.
  # If the filesystem is already broken, running find itself fails with "Input/output error", which is caught too.
  walk = command('sudo find / -xdev > /dev/null')
  describe 'Errors reading the root filesystem' do
    subject { walk.stderr.lines.grep(fs_read_errors) }
    it { should be_empty }
  end

  kernel_log = command('sudo dmesg')
  describe kernel_log do
    its('exit_status') { should eq 0 }
  end
  describe 'Filesystem and I/O errors in the kernel log' do
    subject { kernel_log.stdout.lines.grep(kernel_fs_errors) }
    it { should be_empty }
  end
end
