# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Parse and get RAID shared directory info and turn into an array
raid_shared_dir = node['cluster']['raid_shared_dir']

unless raid_shared_dir.empty?
  raid_shared_dir = format_directory(raid_shared_dir)
  exported_raid_shared_dir = format_directory(raid_shared_dir)

  # Created RAID shared mount point
  directory raid_shared_dir do
    mode '1777'
    owner 'root'
    group 'root'
    action :create
  end

  # Mount RAID directory over NFS
  mount raid_shared_dir do
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{exported_raid_shared_dir}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    action %i(mount enable)
    retries 10
    retry_delay 6
  end
end
