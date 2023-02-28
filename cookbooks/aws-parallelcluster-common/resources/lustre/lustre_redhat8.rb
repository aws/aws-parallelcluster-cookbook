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
  if node['platform_version'].to_f < 8.2
    Chef::Log.warn("FSx for Lustre is not supported in this RHEL version #{node['platform_version']}, supported versions are >= 8.2")
  elsif node['cluster']['kernel_release'].include? "4.18.0-425.3.1.el8"
    Chef::Log.warn("FSx for Lustre is not supported in kernel version 4.18.0-425.3.1.el8 of RHEL, please update the kernel version")
  else
    action_install_lustre
  end
end

action_class do
  def base_url
    "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/$basearch"
  end

  def public_key
    "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc"
  end
end
