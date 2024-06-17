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

provides :nvidia_dcgm, platform: 'ubuntu' do |node|
  node['platform_version'].to_i >= 20
end

use 'partial/_nvidia_dcgm_common.rb'
use 'partial/_nvidia_dcgm_debian.rb'

def _nvidia_dcgm_enabled
  _nvidia_enabled
end

def platform
  "ubuntu#{node['platform_version'].delete('.')}"
end
