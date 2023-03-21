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

control 'tag:config_expected_versions_of_nvidia_driver_cuda_and_gdrcopy_installed' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) && !os_properties.redhat8? && !instance.custom_ami?
  end

  expected_nvidia_driver_version = node['cluster']['nvidia']['driver_version']

  describe "nvidia driver version is expected to be #{expected_nvidia_driver_version}" do
    subject { command('modinfo -F version nvidia').stdout.strip }
    it { should eq expected_nvidia_driver_version }
  end

  expected_cuda_version = node['cluster']['nvidia']['cuda_version']
  cmd = %(
    export PATH=/usr/local/cuda-#{expected_cuda_version}/bin:${PATH};
    export LD_LIBRARY_PATH=/usr/local/cuda-#{expected_cuda_version}/lib64:${LD_LIBRARY_PATH}
    nvcc -V | grep -E -o "release [0-9]+.[0-9]+"
  )

  describe "cuda version is expected to be #{expected_cuda_version}" do
    subject { command(cmd).stdout.strip }
    it { should eq "release #{expected_cuda_version}" }
  end

  expected_gdrcopy_version = node['cluster']['nvidia']['gdrcopy']['version']

  describe "gdrcopy version is expected to be #{expected_gdrcopy_version}" do
    subject { command('modinfo -F version gdrdrv').stdout.strip() }
    it { should eq expected_gdrcopy_version }
  end
end

control 'tag:config_gdrcopy_enabled_on_graphic_instances' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) && !os_properties.redhat8? &&
      !instance.custom_ami? && instance.graphic?
  end

  describe 'gdrcopy service should be enabled' do
    subject { command("systemctl is-enabled #{node['cluster']['nvidia']['gdrcopy']['service']} | grep enabled") }
    its('exit_status') { should eq 0 }
  end

  ['sanity', 'copybw', 'copylat', 'apiperf -s 8'].each do |cmd|
    describe "NVIDIA GDRCopy works properly with #{cmd}" do
      subject { command(cmd) }
      its('exit_status') { should eq 0 }
    end
  end
end

control 'tag:config_gdrcopy_disabled_on_non_graphic_instances' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) && !os_properties.redhat8? &&
      !instance.custom_ami? && !instance.graphic?
  end

  describe 'gdrcopy service should be disabled' do
    subject { command("systemctl is-enabled #{node['cluster']['nvidia']['gdrcopy']['service']} | grep disabled") }
    its('exit_status') { should eq 0 }
  end
end
