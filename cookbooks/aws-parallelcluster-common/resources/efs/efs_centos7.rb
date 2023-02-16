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

provides :efs, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end
unified_mode true

use 'partial/_build_install_efs_utils_centos_redhat'
use 'partial/_mount_umount'

default_action :install_efs_utils

action :install_efs_utils do
  package 'rpm-build' do
    retries 3
    retry_delay 5
  end

  action_build_install_efs_utils
end
