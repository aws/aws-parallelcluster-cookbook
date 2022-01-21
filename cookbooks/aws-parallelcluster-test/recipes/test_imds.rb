# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: test_imds
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# We are going to test all system users only during kitchen tests because it takes ~1.5 minutes.
# During cluster creation we are going to test only a sample of relevant system users,
# that are those who could be privileged plus three more users.
all_users = get_system_users
users_under_test =
  if kitchen_test?
    all_users
  else
    node['cluster']['head_node_imds_allowed_users'] +
      (all_users - node['cluster']['head_node_imds_allowed_users'])[0, 3]
  end

allowed_users =
  if node['cluster']['node_type'] == 'HeadNode' &&
     node['cluster']['scheduler'] != 'awsbatch' &&
     node['cluster']['head_node_imds_secured'] == 'true'
    node['cluster']['head_node_imds_allowed_users']
  else
    users_under_test
  end

denied_users = users_under_test - allowed_users

allowed_users.each { |allowed_user| check_imds_access(allowed_user, true) }

denied_users.each { |denied_user| check_imds_access(denied_user, false) }

if node['cluster']['node_type'] == 'HeadNode' && node['cluster']['scheduler'] != 'awsbatch'
  execute 'check parallelcluster-iptables service is enabled' do
    command "systemctl is-enabled parallelcluster-iptables"
  end
  check_run_level_script('parallelcluster-iptables', %w(1 2 3 4 5), %w(0 6))
  check_iptables_rules_file('/etc/parallelcluster/sysconfig/iptables.rules')
end
