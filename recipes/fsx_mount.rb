# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: fsx_mount
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

fsx_shared_dir = node['cluster']['fsx_options'].split(',')[0]

# Check to see if FSx is created
if fsx_shared_dir != "NONE"

  # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
  fsx_shared_dir = "/#{fsx_shared_dir}" unless fsx_shared_dir.start_with?('/')

  dns_name = if node['cluster']['fsx_dns_name'] && !node['cluster']['fsx_dns_name'].empty?
               node['cluster']['fsx_dns_name']
             else
               # Hardcoded DNSname only valid for filesystem created after Mar-1 2021
               # For older filesystems, DNSname needs to be retrieved from FSx API
               "#{node['cluster']['fsx_fs_id']}.fsx.#{node['cluster']['region']}.amazonaws.com"
             end

  fsx_device = "#{dns_name}@tcp:/#{node['cluster']['fsx_mount_name']}"

  fs_type = 'lustre'

  mount_options = %w[defaults _netdev flock user_xattr noatime]
  mount_options.concat(%w[noauto x-systemd.automount]) if node['init_package'] == 'systemd'

  # Directories are shared from the head node towards the compute nodes.
  # So, the head node must copy the content of existing directories to the device before sharing them.
  if node['cluster']['node_type'] == 'HeadNode' && File.directory?(fsx_shared_dir)
    copy_to_device(fsx_shared_dir, fsx_device, fs_type, mount_options)
  end

  # Create the FSx shared directory, if it does not exist
  directory fsx_shared_dir do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
    not_if { ::File.directory?(fsx_shared_dir) }
  end

  # Mount FSx over NFS
  mount fsx_shared_dir do
    device fsx_device
    fstype fs_type
    dump 0
    pass 0
    options mount_options.join(',')
    action %i[mount enable]
    retries 10
    retry_delay 6
  end
end
