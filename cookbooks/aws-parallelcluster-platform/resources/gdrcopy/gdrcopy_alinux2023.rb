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

provides :gdrcopy, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_gdrcopy_common.rb'
use 'partial/_gdrcopy_common_rhel.rb'

def gdrcopy_enabled?
  nvidia_enabled?
end

def gdrcopy_platform
  '.el8'
end

def gdrcopy_arch
  arm_instance? ? 'aarch64' : 'x86_64'
end
