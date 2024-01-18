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

provides :arm_pl, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end

use 'partial/_arm_pl_common.rb'

action :arm_pl_prerequisite do
  # Needed by arm_pl
  # binutils v2.30 is required for Centos7 architecture detection
  # these must be installed in this order
  package 'centos-release-scl-rh'
  package 'devtoolset-8-binutils'
end

action_class do
  def armpl_platform
    'RHEL-7'
  end

  def gcc_major_minor_version
    '9.3'
  end
end
