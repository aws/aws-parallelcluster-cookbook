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

provides :lustre, platform: 'rocky' do |node|
  node['platform_version'].to_i >= 8
end
unified_mode true

use 'partial/_install_lustre_centos_redhat'
use 'partial/_mount_unmount'

default_action :setup

action :setup do
  version = node['platform_version']
  log "Installing FSx for Lustre. Platform version: #{version}, kernel version: #{node['cluster']['kernel_release']}"
  if version.length == 3 # If version is 8.10 or more, this block is skipped
    if version.to_f < 8.2
      raise "FSx for Lustre is not supported in this Rocky Linux version #{version}, supported versions are >= 8.2"
    elsif version.to_f == 8.7 && (node['cluster']['kernel_release'].include?("4.18.0-425.3.1.el8") || node['cluster']['kernel_release'].include?("4.18.0-425.13.1.el8_7"))
      # Rhel8.7 kernel 4.18.0-425.3.1.el8 and 4.18.0-425.13.1.el8_7 has broken kABI compat
      # See https://access.redhat.com/solutions/6985596 and https://github.com/openzfs/zfs/issues/14724
      raise "FSx for Lustre is not supported in kernel version #{node['cluster']['kernel_release']} of Rocky Linux #{version}, please update the kernel version"
    else
      action_install_lustre
    end
  end
end

action_class do
  def base_url
    # https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html#lustre-client-rhel
    "https://fsx-lustre-client-repo.s3.amazonaws.com/el/#{node['platform_version']}/$basearch"
  end

  def public_key
    "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc"
  end
end
