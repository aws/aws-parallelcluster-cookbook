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

control 'tag:config_nvidia-fabricmanager_enabled' do
  only_if do
    instance.nvs_switch_enabled?
  end

  describe service('nvidia-fabricmanager') do
    it { should be_enabled }
    it { should be_running }
  end
end

control 'tag:config_gdrcopy_enabled_on_graphic_instances' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) &&
      !instance.custom_ami? && instance.graphic?
  end

  describe 'gdrcopy service should be enabled' do
    subject { command("systemctl is-enabled #{node['cluster']['nvidia']['gdrcopy']['service']} | grep enabled") }
    its('exit_status') { should eq 0 }
  end

  if instance.gpudirect_rdma_supported?
    ['sanity', 'copybw', 'copylat', 'apiperf -s 8'].each do |cmd|
      describe "NVIDIA GDRCopy works properly with #{cmd}" do
        subject { command(cmd) }
        its('exit_status') { should eq 0 }
      end
    end
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

control 'tag:config_gdrcopy_disabled_on_non_graphic_instances' do
  only_if do
    !(os_properties.centos7? && os_properties.arm?) &&
      !instance.custom_ami? && !instance.graphic?
  end

  describe 'gdrcopy service should be disabled' do
    subject { command("systemctl is-enabled #{node['cluster']['nvidia']['gdrcopy']['service']} | grep disabled") }
    its('exit_status') { should eq 0 }
  end
end
