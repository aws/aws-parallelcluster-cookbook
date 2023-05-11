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

control 'ssh_target_checker_script_created' do
  title 'Check that ssh_target_checker.sh is created correctly'

  describe file('/usr/bin/ssh_target_checker.sh') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match /VPC_CIDR_LIST=\(cidr1 cidr2\)/ }
  end
end

control 'tag:config_ssh_target_checker_contains_correct_vpc_cidr_list' do
  only_if { !os_properties.on_docker? }

  ssh_target_checker_script = '/usr/bin/ssh_target_checker.sh'

  vpc_cidr_list = node['ec2']['network_interfaces_macs'][node['ec2']['mac']]['vpc_ipv4_cidr_blocks']
                  .split(/\n+/)

  describe file(ssh_target_checker_script) do
    it { should exist }
    its('content') { should match /VPC_CIDR_LIST=\(#{vpc_cidr_list.join(' ')}\)/ }
  end
end

control 'tag:config_ssh_is_correctly_configured' do
  describe file('/etc/ssh/ssh_config') do
    its('content') { should match %r{Match exec "ssh_target_checker.sh %h"\n  StrictHostKeyChecking no\n  UserKnownHostsFile /dev/null} }
  end
end
