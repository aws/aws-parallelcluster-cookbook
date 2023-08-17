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

provides :spack, platform: 'ubuntu', platform_version: '20.04'

use 'partial/_spack_common.rb'

def dependencies
  %w(build-essential ca-certificates coreutils curl environment-modules gfortran git gpg
     lsb-release python3 python3-distutils python3-venv unzip zip)
end

def libfabric_path
  '/opt/amazon/efa/lib/pkgconfig/libfabric.pc'
end

action :setup do
  action_install_spack
end
