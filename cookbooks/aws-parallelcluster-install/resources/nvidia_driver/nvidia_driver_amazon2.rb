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

provides :nvidia_driver, platform: 'amazon', platform_version: '2'

use 'partial/_nvidia_driver_common.rb'

action :set_compiler do
  # Amazon linux 2 with Kernel 5 need to set CC to /usr/bin/gcc10-gcc using dkms override
  if node['kernel']['release'].split('.')[0].to_i == 5
    package "gcc10" do
      retries 10
      retry_delay 5
    end
    cookbook_file 'dkms/nvidia.conf' do
      source 'dkms/nvidia.conf'
      cookbook 'aws-parallelcluster-install'
      path '/etc/dkms/nvidia.conf'
      owner 'root'
      group 'root'
      mode '0644'
    end
  end
end

action :rebuild_initramfs do
  # do nothing
end
