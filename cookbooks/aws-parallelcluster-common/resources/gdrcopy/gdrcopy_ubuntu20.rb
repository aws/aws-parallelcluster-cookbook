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

provides :gdrcopy, platform: 'ubuntu', platform_version: '20.04'

use 'partial/_gdrcopy_common.rb'
use 'partial/_gdrcopy_common_debian.rb'

unified_mode true
default_action :setup

action :setup do
  return unless node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true
  action_gdrcopy_installation
end

action_class do
  def gdrcopy_platform
    'Ubuntu20_04'
  end
end
