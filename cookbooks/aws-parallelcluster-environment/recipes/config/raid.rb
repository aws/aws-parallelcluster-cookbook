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
return if raid_shared_dir.empty?

case node['cluster']['node_type']
when 'HeadNode'
  raid "add raid" do
    raid_shared_dir raid_shared_dir
    raid_type node['cluster']['raid_type']
    raid_vol_array node['cluster']['raid_vol_ids'].split(',')
    action %i(mount export)
    not_if { raid_shared_dir.empty? }
  end

when 'ComputeFleet', 'LoginNode'
  volume "mount raid volume over NFS" do
    action :mount
    shared_dir raid_shared_dir
    device(lazy { "#{node['cluster']['head_node_private_ip']}:#{raid_shared_dir}" })
    fstype 'nfs'
    options node['cluster']['nfs']['hard_mount_options']
    retries 10
    retry_delay 6
  end
else

  raise "node_type must be HeadNode, LoginNode or ComputeFleet"
end
