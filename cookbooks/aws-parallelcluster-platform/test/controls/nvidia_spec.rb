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

control 'tag:install_expected_versions_of_nvidia_driver_installed' do
  only_if do
    !instance.custom_ami? && !(os_properties.centos7? && os_properties.arm?) &&
      (node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true)
  end

  expected_nvidia_driver_version = node['cluster']['nvidia']['driver_version']

  describe "nvidia driver version is expected to be #{expected_nvidia_driver_version}" do
    subject { command('modinfo -F version nvidia').stdout.strip }
    it { should eq expected_nvidia_driver_version }
  end
end

control 'tag:install_expected_versions_of_nvidia_cuda_installed' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) && !instance.custom_ami? &&
      (node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true)
  end

  expected_cuda_version = node['cluster']['nvidia']['cuda']['version']
  cmd = %(
    export PATH=/usr/local/cuda-#{expected_cuda_version}/bin:${PATH};
    export LD_LIBRARY_PATH=/usr/local/cuda-#{expected_cuda_version}/lib64:${LD_LIBRARY_PATH}
    nvcc -V | grep -E -o "release [0-9]+.[0-9]+"
  )

  describe "cuda version is expected to be #{expected_cuda_version}" do
    subject { command(cmd).stdout.strip }
    it { should eq "release #{expected_cuda_version}" }
  end
end

control 'tag:config_nvidia_uvm_and_persistenced_on_graphic_instances' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) &&
      !instance.custom_ami? && instance.graphic?
  end

  describe kernel_module('nvidia_uvm') do
    it { should be_loaded }
  end

  describe file('/etc/modules-load.d/nvidia.conf') do
    its('content') { should include("uvm") }
  end

  describe service('parallelcluster_nvidia') do
    it { should be_enabled }
    it { should be_running }
  end
end
