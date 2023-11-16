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

control 'tag:testami_tag:config_services_disabled_on_debian_family' do
  title 'Test that DLAMI multi eni helper is disabled and masked on debian family'

  only_if { os_properties.debian_family? && !os_properties.on_docker? }

  describe service('aws-ubuntu-eni-helper') do
    it { should_not be_enabled }
    it { should_not be_running }
  end

  describe bash('systemctl list-unit-files --state=masked --no-legend') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /aws-ubuntu-eni-helper.service\s*masked/ }
  end
end

control 'tag:testami_tag:config_services_disabled_on_amazon_family' do
  title 'Test that log4j-cve-2021-44228-hotpatch is disabled and masked on amazon family'

  only_if { os_properties.amazon_family? && !os_properties.on_docker? }

  describe service('log4j-cve-2021-44228-hotpatch') do
    it { should_not be_enabled }
    it { should_not be_running }
  end

  describe bash('systemctl list-unit-files --state=masked --no-legend') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /log4j-cve-2021-44228-hotpatch.service\s*masked/ }
  end

  describe bash('systemctl show -p LoadState log4j-cve-2021-44228-hotpatch') do
    its(:exit_status) { should eq 0 }
    its(:stdout) { should match /LoadState=masked/ }
  end
end
