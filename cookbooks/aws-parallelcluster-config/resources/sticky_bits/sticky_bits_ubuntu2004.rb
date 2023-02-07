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

provides :sticky_bits, platform: 'ubuntu', platform_version: '20.04'
unified_mode true

action :setup do
  # Restore old behavior with sticky bits in Ubuntu 20 to allow root writing to files created by other users
  sysctl 'fs.protected_regular' do
    value 0
  end
end
