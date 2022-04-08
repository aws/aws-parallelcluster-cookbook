# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: fsx_mount
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

fsx_fs_id_array = node['cluster']['fsx_fs_ids'].split(',')
fsx_shared_dir_array = node['cluster']['fsx_shared_dirs'].split(',')
fsx_dns_name_array = node['cluster']['fsx_dns_names'].split(',')
fsx_mount_name_array = node['cluster']['fsx_mount_names'].split(',')
# Check to see if FSx is created
fsx_fs_id_array.each_with_index do |fsx_fs_id, index|
  fsx_shared_dir = fsx_shared_dir_array[index]
  fsx_dns_name = fsx_dns_name_array[index]
  # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
  fsx_shared_dir = "/#{fsx_shared_dir}" unless fsx_shared_dir.start_with?('/')

  # Create the shared directories
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
  end

  dns_name = if fsx_dns_name && !fsx_dns_name.empty?
               fsx_dns_name
             else
               # Hardcoded DNSname only valid for filesystem created after Mar-1 2021
               # For older filesystems, DNSname needs to be retrieved from FSx API
               "#{fsx_fs_id}.fsx.#{node['cluster']['region']}.amazonaws.com"
             end

  mount_name = fsx_mount_name_array[index]
  mount_options = %w(defaults _netdev flock user_xattr noatime)

  mount_options.concat(%w(noauto x-systemd.automount))

  # Mount FSx over NFS
  mount fsx_shared_dir do
    device "#{dns_name}@tcp:/#{mount_name}"
    fstype 'lustre'
    dump 0
    pass 0
    options mount_options
    action %i(mount enable)
    retries 10
    retry_delay 6
  end

  # Make sure permission is correct
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
  end
end
