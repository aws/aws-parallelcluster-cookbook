# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

resource_name :set_user_privileges
provides :set_user_privileges
unified_mode true

# Resource to set user privileges

property :grant_sudo_privileges, [true, false],
         default: false,
         description: 'flag to set sudo privileges'

default_action :run

action :run do
  Chef::Log.debug("Called set_user_privileges with grant_sudo_privileges (#{new_resource.grant_sudo_privileges})")

  if new_resource.grant_sudo_privileges

    Chef::Log.info("Set sudo privileges for #{node['cluster']['scheduler_plugin']['user']}")
    # Ensure scheduler user has sudoers capability
    template '/etc/sudoers.d/99-parallelcluster-scheduler-plugin' do
      source 'scheduler_plugin_user/99-parallelcluster-scheduler-plugin.erb'
      owner 'root'
      group 'root'
      mode '0600'
    end
  else
    Chef::Log.info("No sudo privilege is set for #{node['cluster']['scheduler_plugin']['user']}")
  end
end
