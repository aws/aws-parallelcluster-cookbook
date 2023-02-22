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

control 'network_interfaces_configured' do
  title 'Check that network interfaces have been configured'

  desc 'Check script to configure network interface is created'
  describe file('/tmp/configure_nw_interface.sh') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match /^# Configure a specific Network Interface according to the OS/ }
  end

  only_if { !os_properties.virtualized? }

  desc 'Check network interface are configured'
  device_names = bash("ip -o link | awk '{print substr($2, 1, length($2) -1)}' | grep -v lo").stdout.split(/\n+/)
  device_names.each do |device_name|
    if os_properties.debian_family?
      describe file("/etc/netplan/#{device_name}.yaml") do
        it { should exist }
        its('content') { should match /^    #{device_name}:/ }
        its('content') { should match /^\s+table:\s100\d/ }
      end

      describe file("/etc/networkd-dispatcher/routable.d/cleanup-routes.sh") do
        it { should exist }
        its('mode') { should cmp '0755' }
        its('owner') { should eq 'root' }
        its('group') { should eq 'root' }
        its('content') { should match /^logger -t parallelcluster "Removing Automatic route/ }
      end
    else
      describe file("/etc/sysconfig/network-scripts/ifcfg-#{device_name}") do
        it { should exist }
        its('content') { should match /^DEVICE=#{device_name}/ }
      end

      describe file("/etc/sysconfig/network-scripts/route-#{device_name}") do
        it { should exist }
        its('content') { should match /^default via.*\s#{device_name}\stable\s100\d/ }
        its('content') { should match /^default via.*\s#{device_name}\smetric\s100\d/ }
        its('content') { should match /dev\s#{device_name}\stable\s100\d/ }
      end unless device_name == "eth0"  # eth0 is not configured by ParallelCluster scripts

      describe file("/etc/sysconfig/network-scripts/rule-#{device_name}") do
        it { should exist }
        its('content') { should match /^from.*lookup\s100\d/ }
      end
    end

    desc 'Check all NICs have a private IP assigned'
    describe bash("ip a") do
      its('stdout')      { should match /inet.*#{device_name}/ }
    end
  end
end
