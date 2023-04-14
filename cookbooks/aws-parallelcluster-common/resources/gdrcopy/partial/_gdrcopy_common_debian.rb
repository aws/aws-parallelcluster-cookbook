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

action_class do
  def gdrcopy_build_dependencies
    %w(build-essential devscripts debhelper check libsubunit-dev fakeroot pkg-config dkms)
  end

  def gdrcopy_arch
    arm_instance? ? 'arm64' : 'amd64'
  end

  def gdrcopy_version_extended
    "#{node['cluster']['nvidia']['gdrcopy']['version']}-1"
  end

  def installation_code
    <<~COMMAND
    CUDA=/usr/local/cuda ./build-deb-packages.sh
    dpkg -i gdrdrv-dkms_#{gdrcopy_version_extended}_#{gdrcopy_arch}.#{gdrcopy_platform}.deb
    dpkg -i libgdrapi_#{gdrcopy_version_extended}_#{gdrcopy_arch}.#{gdrcopy_platform}.deb
    dpkg -i gdrcopy-tests_#{gdrcopy_version_extended}_#{gdrcopy_arch}.#{gdrcopy_platform}.deb
    dpkg -i gdrcopy_#{gdrcopy_version_extended}_#{gdrcopy_arch}.#{gdrcopy_platform}.deb
    COMMAND
  end
end
