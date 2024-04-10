# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :manage_efs
provides :manage_efs
unified_mode true

property :shared_dir_array, Array, required: true
property :efs_fs_id_array, Array, required: true
property :efs_encryption_in_transit_array, Array, required: false
property :efs_iam_authorization_array, Array, required: false

default_action :mount

action :mount do
  efs_shared_dir_array = new_resource.shared_dir_array.dup
  efs_fs_id_array = new_resource.efs_fs_id_array.dup
  efs_encryption_in_transit_array = new_resource.efs_encryption_in_transit_array.dup
  efs_iam_authorization_array = new_resource.efs_iam_authorization_array.dup

  efs_fs_id_array.each_with_index do |efs_fs_id, index|
    efs_shared_dir = efs_shared_dir_array[index]
    efs_encryption_in_transit = efs_encryption_in_transit_array[index]
    efs_iam_authorization = efs_iam_authorization_array[index]

    # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
    efs_shared_dir = "/#{efs_shared_dir}" unless efs_shared_dir.start_with?('/')

    # See reference of mount options: https://docs.aws.amazon.com/efs/latest/ug/automount-with-efs-mount-helper.html
    mount_options = "_netdev,noresvport"
    if efs_encryption_in_transit == "true"
      mount_options += ",tls"
      if efs_iam_authorization == "true"
        mount_options += ",iam"
      end
    end

    # Create the EFS shared directory
    directory efs_shared_dir do
      owner 'root'
      group 'root'
      mode '1777'
      recursive true
      action :create
    end

    # Mount EFS over NFS
    mount efs_shared_dir do
      device "#{efs_fs_id}:/"
      fstype 'efs'
      options mount_options
      dump 0
      pass 0
      action :mount
      retries 10
      retry_delay 60 # increase to 60s because it takes about 5 minutes for a  managed EFS to be ready to mount after creation complete
      not_if "mount | grep ' #{efs_shared_dir} '"
    end

    mount efs_shared_dir do
      device "#{efs_fs_id}.efs.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}:/"
      fstype 'efs'
      options mount_options
      dump 0
      pass 0
      action :enable
      retries 10
      retry_delay 6
      only_if "mount | grep ' #{efs_shared_dir} '"
    end

    # Make sure EFS shared directory permissions are correct
    directory efs_shared_dir do
      owner 'root'
      group 'root'
      mode '1777'
    end
  end
end

action :unmount do
  efs_shared_dir_array = new_resource.shared_dir_array.dup
  efs_shared_dir_array.each do |efs_shared_dir|
    # Path needs to be fully qualified, for example "shared/temp" becomes "/shared/temp"
    efs_shared_dir = "/#{efs_shared_dir}" unless efs_shared_dir.start_with?('/')
    # Unmount EFS
    execute 'unmount efs' do
      command "umount -fl #{efs_shared_dir}"
      retries 10
      retry_delay 6
      timeout 60
      only_if "mount | grep ' #{efs_shared_dir} '"
    end
    # remove volume from fstab
    delete_lines "remove volume from /etc/fstab" do
      path "/etc/fstab"
      pattern " #{efs_shared_dir} "
    end
    # Delete the EFS shared directory
    directory efs_shared_dir do
      owner 'root'
      group 'root'
      mode '1777'
      recursive false
      action :delete
      only_if { Dir.exist?(efs_shared_dir.to_s) && Dir.empty?(efs_shared_dir.to_s) }
    end
  end
end
