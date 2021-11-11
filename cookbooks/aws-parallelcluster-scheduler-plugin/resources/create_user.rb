# frozen_string_literal: true

# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :create_user
provides :create_user

# Resource to create system user

property :name, String, name_property: true
property :system_users, Array, required: false
property :force_creation, [true, false],
         default: false,
         description: 'force creation if uid/gid already exists'

default_action :run

action :run do
  Chef::Log.debug("Called create_user with system users (#{new_resource.system_users})")

  if new_resource.system_users && !new_resource.system_users.empty?

    new_resource.system_users.each_with_index do |user, index|
      name = user[:Name]
      enable_imds = user[:EnableImds]
      system_user_id = node['cluster']['scheduler_plugin']['system_user_id_start'] + index
      system_group_id = node['cluster']['scheduler_plugin']['system_group_id_start'] + index

      check_gid(system_group_id)
      check_uid(system_user_id)

      Chef::Log.info("Create gid #{system_group_id} group with group name #{name}.")
      group name do
        comment "ParallelCluster scheduler plugin system group #{name}"
        gid system_group_id
        system true
      end

      Chef::Log.info("Create uid #{system_user_id} user with user name #{name}.")
      user name do
        comment "ParallelCluster scheduler plugin system user #{name}"
        uid system_user_id
        gid system_group_id
      end

      if enable_imds
        Chef::Log.info("Add #{name} to head node imds allowed users.")
        node.default['cluster']['head_node_imds_allowed_users'].append(name)
      end
    end
  else
    Chef::Log.info("No system user is created")
  end
end

action_class do
  def check_gid(gid)
    cmd = Mixlib::ShellOut.new("getent group #{gid}")
    check_group_stdout = cmd.run_command.stdout.strip
    return if cmd.error? || new_resource.force_creation

    raise("gid #{gid} is used by #{check_group_stdout}, it should be reserved for ParallelCluster system group. " \
        "Reserved gid range is #{node['cluster']['scheduler_plugin']['system_group_id_start']}-" \
        "#{node['cluster']['scheduler_plugin']['system_group_id_start'] + 9}.")
  end

  def check_uid(uid)
    cmd = Mixlib::ShellOut.new("getent passwd #{uid}")
    check_user_stdout = cmd.run_command.stdout.strip
    return if cmd.error? || new_resource.force_creation

    raise("uid #{uid} is used by #{check_user_stdout}, it should be reserved for ParallelCluster system user. " \
        "Reserved uid range is #{node['cluster']['scheduler_plugin']['system_user_id_start']}-" \
        "#{node['cluster']['scheduler_plugin']['system_user_id_start'] + 9}.")
  end
end
