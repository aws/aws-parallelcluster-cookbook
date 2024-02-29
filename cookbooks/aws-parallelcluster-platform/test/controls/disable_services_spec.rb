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
  services = %w(aws-ubuntu-eni-helper wpa_supplicant)

  title "Test that #{services.join(',')} are disabled and masked on debian family"

  only_if { os_properties.debian_family? && !os_properties.on_docker? }

  services.each do |service_name|
    describe service(service_name) do
      it { should_not be_enabled }
      it { should_not be_running }
    end

    describe bash('systemctl list-unit-files --state=masked --no-legend') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /#{service_name}.service\s*masked/ }
    end
  end
end

control 'tag:testami_tag:config_services_disabled_on_amazon_family' do
  services = %w(log4j-cve-2021-44228-hotpatch cups)

  title "Test that #{services.join(',')} are disabled and masked on amazon family"

  only_if { os_properties.amazon_family? && !os_properties.on_docker? }

  services.each do |service_name|
    describe service(service_name) do
      it { should_not be_enabled }
      it { should_not be_running }
    end

    describe bash('systemctl list-unit-files --state=masked --no-legend') do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /#{service_name}.service\s*masked/ }
    end

    describe bash("systemctl show -p LoadState #{service_name}") do
      its(:exit_status) { should eq 0 }
      its(:stdout) { should match /LoadState=masked/ }
    end
  end
end
