# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

property :fsx, String, name_property: true
property :fsx_fs_id_array, Array, required: %i(mount unmount)
property :fsx_fs_type_array, Array, required: %i(mount unmount)
property :fsx_shared_dir_array, Array, required: %i(mount unmount)
property :fsx_dns_name_array, Array, required: %i(mount unmount)
property :fsx_mount_name_array, Array, required: %i(mount unmount)
property :fsx_volume_junction_path_array, Array, required: %i(mount unmount)

action :mount do
  new_resource.fsx_fs_id_array.dup.each_with_index do |_fsx_fs_id, index|
    fsx = FSx.new(node, new_resource, index)

    # Create the shared directories
    directory fsx.shared_dir do
      owner 'root'
      group 'root'
      mode '1777'
      recursive true
      action :create
    end

    mount fsx.shared_dir do
      device fsx.device_name
      fstype fsx.fstype
      dump 0
      pass 0
      options fsx.mount_options
      action :mount
      retries 10
      retry_delay 6
      not_if "mount | grep ' #{fsx.shared_dir} '"
    end

    mount fsx.shared_dir do
      device fsx.device_name
      fstype fsx.fstype
      dump 0
      pass 0
      options fsx.mount_options
      action :enable
      retries 10
      retry_delay 6
      only_if "mount | grep ' #{fsx.shared_dir} '"
    end

    # Make sure permission is correct.
    # OpenZFS does not allow changing the permission of the root directory.
    # OpenZFS sets the directory permission to 1777 automatically.
    directory "change permissions for #{fsx.shared_dir}" do
      path fsx.shared_dir
      owner 'root'
      group 'root'
      mode '1777'
      only_if { fsx.can_change_shared_dir_permissions && node['cluster']['node_type'] == "HeadNode" }
    end
  end
end

action :unmount do
  new_resource.fsx_fs_id_array.dup.each_with_index do |_fsx_fs_id, index|
    fsx = FSx.new(node, new_resource, index)

    execute "unmount fsx #{fsx.shared_dir}" do
      command "umount -fl #{fsx.shared_dir}"
      retries 10
      retry_delay 6
      timeout 60
      only_if "mount | grep ' #{fsx.shared_dir} '"
    end

    delete_lines "remove volume #{fsx.device_name} from /etc/fstab" do
      path "/etc/fstab"
      pattern "#{fsx.device_name} *"
    end

    # Delete the shared directories
    directory fsx.shared_dir do
      owner 'root'
      group 'root'
      mode '1777'
      recursive true
      action :delete
    end
  end
end

action_class do
  class FSx
    attr_accessor :type, :shared_dir, :device_name, :fstype, :mount_options, :can_change_shared_dir_permissions

    def initialize(node, resource, index)
      @id = resource.fsx_fs_id_array[index]
      @type = resource.fsx_fs_type_array[index]
      @dns_name = resource.fsx_dns_name_array[index]
      @shared_dir = self.class.make_absolute(resource.fsx_shared_dir_array[index])
      @volume_junction_path = self.class.make_absolute(resource.fsx_volume_junction_path_array[index])

      if @dns_name.blank?
        # Region Building Note: DNS names have the default AWS domain (amazonaws.com) also in China and GovCloud.
        @dns_name = "#{@id}.fsx.#{node['cluster']['region']}.amazonaws.com"
      end

      @mount_name = resource.fsx_mount_name_array[index]

      if @type == 'LUSTRE'
        @mount_options = %w(defaults _netdev flock user_xattr noatime noauto x-systemd.automount)
        @device_name = "#{@dns_name}@tcp:/#{@mount_name}"
        @fstype = 'lustre'
      else
        @device_name = "#{@dns_name}:#{@volume_junction_path}"
        @fstype = 'nfs'

        if @type == 'OPENZFS'
          @mount_options = %w(nfsvers=4.2)
        elsif @type == 'ONTAP'
          @mount_options = %w(defaults)
        end
      end

      @can_change_shared_dir_permissions = @type != 'OPENZFS'
    end

    def self.make_absolute(path)
      path.nil? || path.start_with?('/') ? path : "/#{path}"
    end
  end
end
