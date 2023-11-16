# frozen_string_literal: true

# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :efs, platform: 'amazon', platform_version: '2'

use 'partial/_get_package_version_rpm'
use 'partial/_common'
use 'partial/_mount_umount'

action :install_utils do
  package_name = "amazon-efs-utils"

  # Do not install efs-utils if a same or newer version is already installed.
  return if already_installed?(package_name, new_resource.efs_utils_version)

  # On Amazon Linux 2, amazon-efs-utils and stunnel are installed from OS repo.
  package package_name do
    retries 3
    retry_delay 5
  end
  action_increase_poll_interval
end
