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

control 'tag:install_expected_versions_of_nvidia_gdrcopy_installed' do
  only_if do
    !instance.custom_ami? &&
      (node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true)
  end

  expected_gdrcopy_version = node['cluster']['nvidia']['gdrcopy']['version'].split('.')[0..1].join('.')

  describe "gdrcopy version is expected to be #{expected_gdrcopy_version}" do
    subject { command('modinfo -F version gdrdrv').stdout.strip() }
    it { should eq expected_gdrcopy_version }
  end
end

# Service is gdrdrv on Debian/Ubuntu, gdrcopy on RHEL. Derive from OS, not a
# node attribute, which is unset when the install is skipped (e.g. DLAMI).
gdrcopy_service = os_properties.debian_family? ? 'gdrdrv' : 'gdrcopy'

control 'tag:config_gdrcopy_enabled_on_graphic_instances' do
  only_if do
    !instance.custom_ami? && instance.graphic?
  end

  describe 'gdrcopy service should be enabled' do
    subject { command("systemctl is-enabled #{gdrcopy_service} | grep enabled") }
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

control 'tag:config_gdrcopy_disabled_on_non_graphic_instances' do
  only_if do
    !instance.custom_ami? && !instance.graphic? &&
      (node['cluster']['nvidia']['enabled'] == 'yes' || node['cluster']['nvidia']['enabled'] == true)
  end

  describe 'gdrcopy service should be disabled' do
    subject { command("systemctl is-enabled #{gdrcopy_service}") }
    its('exit_status') { should eq 1 }
  end
end
