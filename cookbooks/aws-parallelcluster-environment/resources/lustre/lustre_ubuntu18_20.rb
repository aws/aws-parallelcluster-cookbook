# frozen_string_literal: true

#
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

provides :lustre, platform: 'ubuntu' do |node|
  node['platform_version'].to_i < 22
end
unified_mode true

use 'partial/_install_lustre_debian'
use 'partial/_mount_unmount'

default_action :setup

action_class do
  def filecache_mount_options
    # Following https://docs.aws.amazon.com/fsx/latest/FileCacheGuide/mount-fs-auto-mount-onreboot.html to Mount FileCache
    %w(defaults _netdev flock user_xattr noatime noauto x-systemd.automount x-systemd.requires=network.service)
  end
end
