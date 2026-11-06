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
# See the License for the specific language governing permissions and limitations under the License
provides :dcv, platform: 'ubuntu' do |node|
  node['platform_version'].to_i == 26
end

use 'partial/_dcv_common'
use 'partial/_ubuntu_common'

# Ubuntu 26.04 only supports Wayland. With Wayland, DCV supports virtual sessions only
# and does not ship xdcv and dcv-gl.
def dcv_sha256sum
  if arm_instance?
    '589431ebd3818ec7b14a8c61e6cf18caf1fe4af34fa60993f6f80059d082be17'
  else
    '92765147dc09f1b2a6c08c7d35fc81f7cad810dcd43d0a5fb6c8cc244094afde'
  end
end

def dcv_package_files
  %W(#{dcv_server} #{dcv_web_viewer})
end

action_class do
  # With Wayland the GPU is used without Xorg and dcv-gl: only start the graphical session.
  def allow_gpu_acceleration
    bash 'set default systemd runlevel to graphical.target' do
      user 'root'
      code <<-SETUPGRAPHICAL
      set -e
      systemctl set-default graphical.target
      systemctl isolate graphical.target &
      SETUPGRAPHICAL
    end
  end
end
