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

provides :gdrcopy, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end

node.default['gdrcopy_version'] = '2.3.1'
node.default['gdrcopy_checksum'] = '59b3cc97a4fc6008a5407506d9e67ecc4144cfad61c261217fabcb671cd30ca8'

use 'partial/_gdrcopy_common.rb'
use 'partial/_gdrcopy_common_rhel.rb'

# The installation code must be overridden in Centos7
# because it has GDRCopy pinned to v2.3.1.
def installation_code
  <<~COMMAND
  CUDA=/usr/local/cuda ./build-rpm-packages.sh
  rpm -q gdrcopy-kmod-#{gdrcopy_version_extended}dkms || rpm -Uvh gdrcopy-kmod-#{gdrcopy_version_extended}dkms.noarch.#{gdrcopy_platform}.rpm
  rpm -q gdrcopy-#{gdrcopy_version_extended}.#{gdrcopy_arch} || rpm -Uvh gdrcopy-#{gdrcopy_version_extended}.#{gdrcopy_arch}.#{gdrcopy_platform}.rpm
  rpm -q gdrcopy-devel-#{gdrcopy_version_extended}.noarch || rpm -Uvh gdrcopy-devel-#{gdrcopy_version_extended}.noarch.#{gdrcopy_platform}.rpm
  COMMAND
end

def gdrcopy_enabled?
  !arm_instance? && nvidia_enabled?
end

def gdrcopy_platform
  'el7'
end

def gdrcopy_arch
  arm_instance? ? 'arm64' : 'x86_64'
end
