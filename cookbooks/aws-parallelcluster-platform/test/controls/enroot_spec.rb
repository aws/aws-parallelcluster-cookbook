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

control 'tag:install_expected_version_of_enroot_installed' do
  only_if { !os_properties.on_docker? && ['yes', true].include?(node['cluster']['nvidia']['enabled']) }

  expected_enroot_version = node['cluster']['enroot']['version']

  describe "gdrcopy version is expected to be #{expected_enroot_version}" do
    subject { command('enroot version').stdout.strip() }
    it { should eq expected_enroot_version }
  end
end

control 'tag:config_enroot_enabled_on_graphic_instances' do
  only_if { !os_properties.on_docker? && ['yes', true].include?(node['cluster']['nvidia']['enabled']) }

  describe file("/opt/parallelcluster/shared/enroot") do
    it { should exist }
    its('group') { should eq 'root' }
  end unless os_properties.redhat_on_docker?
end

control 'tag:config_enroot_disabled_on_non_graphic_instances' do
  only_if { !os_properties.on_docker? && !['yes', true].include?(node['cluster']['nvidia']['enabled']) }

  describe 'enroot service should be disabled' do
    subject { command("enroot version") }
    its('exit_status') { should eq 127 }
  end
end
