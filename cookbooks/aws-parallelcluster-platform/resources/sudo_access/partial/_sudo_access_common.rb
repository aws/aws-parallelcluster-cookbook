# frozen_string_literal: true
#
# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

property :user_name, String, default: node['cluster']['cluster_user']

action :setup do
  node['cluster']['disable_sudo_access_for_default_user'] == 'true' ? action_disable : action_enable
end

action :enable do
  Chef::Log.info("Enabling Sudo Access for #{new_resource.user_name}")
  # Enable sudo access for default user
  template '/etc/sudoers.d/99-parallelcluster-revoke-sudo-access' do
    only_if { ::File.exist? "/etc/sudoers.d/99-parallelcluster-revoke-sudo-access" }
    source 'sudo_access/99-parallelcluster-revoke-sudo.erb'
    cookbook 'aws-parallelcluster-platform'
    action :delete
  end
end

action :disable do
  Chef::Log.info("Disabling Sudo Access for #{new_resource.user_name}")
  replace_or_add "Disable Sudo Access for #{new_resource.user_name}" do
    path "/etc/sudoers"
    pattern "^#{new_resource.user_name}*"
    line ""
    remove_duplicates true
    replace_only true
  end

  # Disable sudo access for default user
  template '/etc/sudoers.d/99-parallelcluster-revoke-sudo-access' do
    source 'sudo_access/99-parallelcluster-revoke-sudo.erb'
    cookbook 'aws-parallelcluster-platform'
    owner 'root'
    group 'root'
    mode '0600'
    variables(
      user_name: new_resource.user_name
    )
    action :create
  end
end
