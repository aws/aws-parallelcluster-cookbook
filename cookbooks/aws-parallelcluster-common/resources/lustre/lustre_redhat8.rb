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

provides :lustre, platform: 'redhat' do |node|
  node['platform_version'].to_i == 8
end
unified_mode true

use 'partial/_install_lustre_centos_redhat'
use 'partial/_mount_unmount'

default_action :setup

action :setup do
  version = node['platform_version']
  if version.to_f < 8.2
    log "FSx for Lustre is not supported in this RHEL version #{version}, supported versions are >= 8.2" do
      level :warn
    end
  else
    action_install_lustre
  end
end

def find_os_minor_version
  os_minor_version = ''
  kernel_patch_version = find_kernel_patch_version

  # kernel patch version less than 193 is equivalent to a RHEL 8.2
  os_minor_version = '2' if kernel_patch_version >= '193'
  os_minor_version = '3' if kernel_patch_version >= '240'
  os_minor_version = '4' if kernel_patch_version >= '305'
  os_minor_version = '5' if kernel_patch_version >= '348'
  os_minor_version = '6' if kernel_patch_version >= '372'
  os_minor_version = '7' if kernel_patch_version >= '425'

  os_minor_version
end

action_class do
  def base_url
    # https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html#lustre-client-rhel
    "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8.#{find_os_minor_version}/$basearch"
  end

  def public_key
    "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc"
  end
end
