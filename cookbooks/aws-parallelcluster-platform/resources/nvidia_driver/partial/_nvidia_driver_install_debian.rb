# frozen_string_literal: true
#
# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# Prepare the system for the driver meta-package install.
# Lock the driver to the exact version using NVIDIA's official version-locking package,
# installed *before* the driver as NVIDIA recommends. This
# pin is required on Debian/Ubuntu specifically: `nvidia-open`/`cuda-drivers` are
# "latest driver" meta-packages, so without the pin apt would resolve the driver to
# the newest version available across all enabled apt sources rather than the version
# shipped by our local repo, mismatching Fabric Manager / IMEX and the version recorded
# for the InSpec tests. The pinning package ships a precompiled apt-preferences file so we don't
# hand-maintain one.
# See https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/latest/version-locking.html
action :prepare_driver_install do
  apt_package "nvidia-driver-pinning-#{new_resource.nvidia_driver_version}" do
    retries 3
    retry_delay 5
  end
end
