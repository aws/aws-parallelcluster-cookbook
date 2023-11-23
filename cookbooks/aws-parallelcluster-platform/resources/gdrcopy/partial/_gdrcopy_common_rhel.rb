# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

def gdrcopy_service
  'gdrcopy'
end

def gdrcopy_build_dependencies
  %w(dkms rpm-build make check check-devel subunit subunit-devel)
end

def installation_code
  <<~COMMAND
  CUDA=/usr/local/cuda ./build-rpm-packages.sh
  rpm -q gdrcopy-kmod-#{gdrcopy_version_extended}dkms || rpm -Uvh gdrcopy-kmod-#{gdrcopy_version_extended}dkms.#{gdrcopy_platform}.noarch.rpm
  rpm -q gdrcopy-#{gdrcopy_version_extended}.#{gdrcopy_arch} || rpm -Uvh gdrcopy-#{gdrcopy_version_extended}.#{gdrcopy_platform}.#{gdrcopy_arch}.rpm
  rpm -q gdrcopy-devel-#{gdrcopy_version_extended}.noarch || rpm -Uvh gdrcopy-devel-#{gdrcopy_version_extended}.#{gdrcopy_platform}.noarch.rpm
  COMMAND
end
