# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-scheduler-plugin
# Recipe:: init_user
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

# create scheduler plugin users in config file
create_user 'Create scheduler plugin users' do
  system_users(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :SchedulerDefinition, :SystemUsers) })
  grant_sudo_privileges(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :GrantSudoPrivileges) })
end

# set sudo privileges for scheduler plugin user
set_user_privileges 'Set sudo privileges' do
  grant_sudo_privileges(lazy { node['cluster']['config'].dig(:Scheduling, :SchedulerSettings, :GrantSudoPrivileges) })
end
