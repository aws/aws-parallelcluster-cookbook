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

control 'fs_data_file_created_correctly' do
  title 'Check that shared storage info are added correctly to the data file'

  describe file("/etc/parallelcluster/shared_storages_data.yaml") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match /^ebs:/ }
    its('content') { should match /- volume_id: volume1/ }
    its('content') { should match /mount_dir: ebs1/ }
    its('content') { should match /^raid:/ }
    its('content') { should match /- raid_shared_dir: raid1/ }
    its('content') { should match /raid_type: 1/ }
    its('content') { should match /raid_vol_array: volume1,volume2/ }
    its('content') { should match /^efs:/ }
    its('content') { should match /- efs_fs_id: efs-id2/ }
    its('content') { should match /mount_dir: efs2/ }
    its('content') { should match /efs_encryption_in_transit: false/ }
    its('content') { should match /efs_iam_authorization: iam2/ }
    its('content') { should match /^fsx:/ }
    its('content') { should match /- fsx_fs_id: fsx-id2/ }
    its('content') { should match /mount_dir: fsx2/ }
    its('content') { should match /fsx_fs_type: type2/ }
    its('content') { should match /fsx_dns_name: dns2/ }
    its('content') { should match /fsx_mount_name: mount2/ }
    its('content') { should match /fsx_volume_junction_path: value2/ }
  end
end

control 'fs_data_file_with_default_values' do
  title 'Check that shared storage info are not added to the data file'

  describe file("/etc/parallelcluster/shared_storages_data.yaml") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match /^ebs:/ }
    its('content') { should_not match %r{mount_dir: /shared} }
    its('content') { should match /^raid:/ }
    its('content') { should_not match /raid_type:/ }
    its('content') { should match /^efs:/ }
    its('content') { should_not match /- efs_fs_id:/ }
    its('content') { should match /^fsx:/ }
    its('content') { should_not match /- fsx_fs_id:/ }
  end
end
