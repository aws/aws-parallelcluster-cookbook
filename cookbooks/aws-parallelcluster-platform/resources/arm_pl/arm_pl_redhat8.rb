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

provides :arm_pl, platform: 'redhat' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_arm_pl_common.rb'

action_class do
  def armpl_platform
    "RHEL-#{node['platform_version'].to_i}"
  end

  def gcc_major_minor_version
    case node['platform_version'].to_i
    when 8
      '9.3'
    else
      '11.3'
    end
  end
end
