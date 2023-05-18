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

control 'tag:install_chrony' do
  title 'Test chrony installation and configuration'

  only_if { !os_properties.redhat_ubi? }

  describe package('chrony') do
    it { should be_installed }
  end

  describe package('ntp') do
    it { should_not be_installed }
  end

  describe package('ntpdate') do
    it { should_not be_installed }
  end

  if os.redhat?
    chrony_file = '/etc/chrony.conf'
  elsif os.debian?
    chrony_file = '/etc/chrony/chrony.conf'
  else
    describe "unsupported OS" do
      # this produces a skipped control (ignore-like)
      # adding a new OS to kitchen platform list and running the tests,
      # it would surface the fact this recipe does not support this OS.
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end

  describe file(chrony_file) do
    it { should exist }
    its('content') { should match(/server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4/) }
  end
end

control 'tag:config_chrony_service_configured' do
  title 'Check that chrony is correctly configured'

  only_if { !os_properties.on_docker? }

  chrony_service = os_properties.ubuntu? ? 'chrony' : 'chronyd'

  describe service(chrony_service) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe bash("systemctl show #{chrony_service} | grep 'Restart=no'") do
    its('exit_status') { should eq(0) }
  end

  describe bash("journalctl -u #{chrony_service}") do
    its('exit_status') { should eq 0 }
  end

  describe bash("sudo -u #{node['cluster']['cluster_user']} chronyc waitsync 30; chronyc tracking | grep -i reference | grep 169.254.169.123") do
    its('exit_status') { should eq 0 }
  end
end
