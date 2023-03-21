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

control 'allowed_users_can_access_imds' do
  title 'Check that IMDS has been configured correctly'

  node['cluster']['head_node_imds_allowed_users'].each do |user|
    describe "user ${user} is allowed to access imds" do
      subject { bash("sudo -u #{user} curl -H 'X-aws-ec2-metadata-token-ttl-seconds: 900' -X PUT 'http://169.254.169.254/latest/api/token'") }
      its('exit_status') { should eq(0) }
    end
  end
end

control 'not_allowed_users_can_not_access_imds' do
  allowed_users = node['cluster']['head_node_imds_allowed_users']
  passwd.users.reject { |user| allowed_users.include?(user) }.each do |user|
    describe "user ${user} is not allowed to access imds" do
      subject { bash("sudo -u #{user} curl -H 'X-aws-ec2-metadata-token-ttl-seconds: 900' -X PUT 'http://169.254.169.254/latest/api/token'") }
      its('exit_status') { should eq(7) }
    end
  end
end

control 'parallelcluster-iptables_correctly_configured' do
  only_if { !os_properties.virtualized? }

  describe service('parallelcluster-iptables') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  %w(1 2 3 4 5).each do |level|
    describe "Check parallelcluster-iptables run level #{level} on" do
      subject { bash("ls /etc/rc#{level}.d/ | egrep '^S[0-9]+parallelcluster-iptables$'") }
      its('exit_status') { should eq(0) }
    end
  end

  %w(0 6).each do |level|
    describe "Check parallelcluster-iptables run level #{level} off" do
      subject { bash("ls /etc/rc#{level}.d/ | egrep '^K[0-9]+parallelcluster-iptables$'") }
      its('exit_status') { should eq(0) }
    end
  end

  describe file('/etc/parallelcluster/sysconfig/iptables.rules') do
    it { should exist }
  end
end
