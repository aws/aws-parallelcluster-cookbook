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

control 'ssh_target_checker_contains_correct_vpc_cidr_list' do
  ssh_target_checker_script = '/usr/bin/ssh_target_checker.sh'

  vpc_cidr_list = node['ec2']['network_interfaces_macs'][node['ec2']['mac']]['vpc_ipv4_cidr_blocks']
                  .split(/\n+/)

  describe file(ssh_target_checker_script) do
    it { should exist }
    its('content') { should match /VPC_CIDR_LIST=\(#{vpc_cidr_list.join(' ')}\)/ }
  end
end
