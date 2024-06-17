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

provides :fabric_manager, platform: 'redhat' do |node|
  node['platform_version'].to_i >= 8
end

use 'partial/_fabric_manager_common.rb'
use 'partial/_fabric_manager_install_rhel.rb'

def fabric_manager_package
  'nvidia-fabric-manager'
end

def fabric_manager_version
  _nvidia_driver_version
end

def platform
  "rhel#{node['platform_version'].to_i}"
end
