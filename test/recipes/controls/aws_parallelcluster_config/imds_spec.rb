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

control 'imds_configured' do
  title 'Check that IMDS has been configured correctly'

  only_if { !os_properties.virtualized? }

  desc 'Check allowed users'
  allowed = %w(root nobody)
  allowed.each do |user|
    describe bash("sudo -u #{user} curl -H 'X-aws-ec2-metadata-token-ttl-seconds: 900' -X PUT 'http://169.254.169.254/latest/api/token'") do
      its('exit_status') { should eq(0) }
    end
  end

  desc 'Check denied users'
  denied = passwd.users.reject { |user| allowed.include?(user) }
  denied.each do |user|
    describe bash("sudo -u #{user} curl -H 'X-aws-ec2-metadata-token-ttl-seconds: 900' -X PUT 'http://169.254.169.254/latest/api/token'") do
      its('exit_status') { should eq(7) }
    end
  end

  desc 'Check that parallelcluster-iptables service is enabled'
  describe service('parallelcluster-iptables') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  desc 'Check parallelcluster-iptables run level on'
  levels_on = %w(1 2 3 4 5)
  levels_on.each do |level|
    describe bash("ls /etc/rc#{level}.d/ | egrep '^S[0-9]+parallelcluster-iptables$'") do
      its('exit_status') { should eq(0) }
    end
  end

  desc 'Check parallelcluster-iptables run level off'
  levels_off = %w(0 6)
  levels_off.each do |level|
    describe bash("ls /etc/rc#{level}.d/ | egrep '^K[0-9]+parallelcluster-iptables$'") do
      its('exit_status') { should eq(0) }
    end
  end

  desc 'Check iptables rules file exists'
  describe file('/etc/parallelcluster/sysconfig/iptables.rules') do
    it { should exist }
  end
end
