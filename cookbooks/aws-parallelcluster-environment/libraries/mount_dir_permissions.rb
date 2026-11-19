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
