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

provides :nfs, platform: 'ubuntu', platform_version: '20.04'
unified_mode true

use 'partial/_install_nfs_debian'
use 'partial/_install_nfs4_and_disable'

action :prepare do
  action_install_nfs
  action_install_nfs4
  action_disable_start_at_boot
end
