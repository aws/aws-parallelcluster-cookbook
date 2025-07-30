# frozen_string_literal: true

# Copyright:: 2025 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :nvidia_imex, platform: 'amazon', platform_version: '2'

use 'partial/_nvidia_imex_common.rb'
use 'partial/_nvidia_imex_rhel.rb'

def imex_installed?
  # We do not install NVIDIA-Imex for Alinux2 due to restriction on NVIDIA driver
  true
end

action :configure do
  # Do nothing
end
