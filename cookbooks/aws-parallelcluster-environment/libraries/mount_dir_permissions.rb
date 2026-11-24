# frozen_string_literal: true

# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# The CLI sets the <storage type>_mount_dir_permissions attributes from SharedStorage/MountDirPermissions,
# with one value per shared storage:
# - a mode, for example 1777: set it on the mount directory after mounting;
# - NONE (SetPermissions: false): do not change the permissions of the mount directory;
# - DEFAULT (MountDirPermissions not set), or no value: use the default mode of the mount resource.
MOUNT_DIR_PERMISSIONS_NONE = 'NONE'
MOUNT_DIR_PERMISSIONS_DEFAULT = 'DEFAULT'

# Return the mode to apply to a mount directory, given its configured value and the default mode.
def mount_dir_mode(value, default_mode)
  value = value.to_s.strip
  return default_mode if value.empty? || value == MOUNT_DIR_PERMISSIONS_DEFAULT
  value
end

# Return true if ParallelCluster must set the given mode on the mount directory.
def set_mount_dir_permissions?(mode)
  mode != MOUNT_DIR_PERMISSIONS_NONE
end

# Return the entry of the given mapping entries for the same storage, ignoring the mount directory permissions,
# so that a change of permissions alone does not unmount and mount the storage again.
def find_storage_in_mapping(storage_entries, storage)
  return if storage_entries.nil?
  storage_entries.find { |entry| entry.except('mount_dir_permissions') == storage.except('mount_dir_permissions') }
end

# Return, by storage type, the entries of the new mapping for the storage that stays mounted during a cluster update
# and whose mount directory permissions change, with mount_dir_permissions set to the mode to apply.
def mount_dir_permissions_changes(previous_mapping, new_mapping)
  new_mapping.to_h do |storage_type, storages|
    changes = (storages || []).filter_map do |storage|
      # The previous entry differs only by the permissions, if any
      previous_storage = find_storage_in_mapping(previous_mapping[storage_type], storage)
      next if previous_storage.nil? || previous_storage == storage

      mount_dir = format_directory(storage['mount_dir'] || storage['raid_shared_dir'])
      mode = mount_dir_mode(storage['mount_dir_permissions'], mount_dir == '/home' ? '755' : '1777')
      storage.merge('mount_dir_permissions' => mode) if set_mount_dir_permissions?(mode)
    end
    [storage_type, changes]
  end
end

# Set the mode of a mount directory on the head node, unless the mode is NONE. The mode is stored in the file system,
# so it applies to every node. Call it from the change_permissions action of a storage resource.
def change_mount_dir_permissions(shared_dir, dir_mode)
  return unless set_mount_dir_permissions?(dir_mode)

  directory "change permissions for #{shared_dir}" do
    path shared_dir
    owner 'root'
    group 'root'
    mode dir_mode
    only_if { node['cluster']['node_type'] == 'HeadNode' }
  end
end
