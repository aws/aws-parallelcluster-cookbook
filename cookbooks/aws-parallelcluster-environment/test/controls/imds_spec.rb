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

control 'tag:config_only_allowed_users_can_access_imds' do
  only_if { !os_properties.on_docker? }

  allowed_users =
    if (%w(HeadNode LoginNode).include? node['cluster']['node_type']) &&
       node['cluster']['scheduler'] != 'awsbatch' &&
       node['cluster']['head_node_imds_secured'] == 'true'
      node['cluster']['head_node_imds_allowed_users']
    else
      passwd.users
    end

  passwd.users.each do |user|
    allowed = allowed_users.include?(user)
    access_descr = allowed ? 'allowed' : 'denied'

    describe "user #{user} is #{access_descr} to access imds" do
      subject { bash("sudo -u #{user} curl -H 'X-aws-ec2-metadata-token-ttl-seconds: 900' -X PUT 'http://169.254.169.254/latest/api/token'") }
      its('exit_status') { should eq(allowed ? 0 : 7) }
    end
  end
end

control 'tag:config_parallelcluster-iptables_correctly_configured' do
  only_if { (instance.head_node? || instance.login_node?) && node['cluster']['scheduler'] != 'awsbatch' && !os_properties.on_docker? }

  describe service('parallelcluster-iptables') do
    it { should be_installed }
    it { should be_enabled }
  end

  describe file("#{node['cluster']['etc_dir']}/sysconfig/iptables.rules") do
    it { should exist }
  end
end
