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

provides :arm_pl, platform: 'ubuntu' do |node|
  node['platform_version'].to_i == 22
end

use 'partial/_arm_pl_common.rb'

property :armpl_major_minor_version, String, default: '23.04'
property :armpl_patch_version, String, default: '1'
property :gcc_major_minor_version, String, default: '11.3'
property :gcc_patch_version, String, default: '0'

action_class do
  def armpl_platform
    "Ubuntu-#{node['platform_version']}"
  end

  def modulefile_dir
    "/usr/share/modules/modulefiles"
  end
end
