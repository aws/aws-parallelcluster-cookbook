# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:install_nvidia_dcgmi_installed' do
  only_if do
    ['yes', true, 'true'].include?(node['cluster']['nvidia']['enabled']) && !instance.custom_ami? && !os_properties.arm?
  end
  describe package('datacenter-gpu-manager-4-cuda13') do
    it { should be_installed }
  end

  # The GPU health check relies on the nvidia-dcgm service not running, to run the diagnostics of concurrent jobs
  # at the same time: the service allows only one diagnostic per node.
  describe service('nvidia-dcgm') do
    it { should_not be_enabled }
    it { should_not be_running }
  end
end
