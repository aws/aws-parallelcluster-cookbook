# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: chrony
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

return if redhat_ubi?

# Install Amazon Time Sync
package %w(ntp ntpdate ntp*) do
  action :remove
end

package %w(chrony) do
  retries 3
  retry_delay 5
end

append_if_no_line "add configuration to chrony.conf" do
  path node['cluster']['chrony']['conf']
  line "server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4"
  notifies :stop, "service[#{node['cluster']['chrony']['service']}]", :immediately
  notifies :reload, "service[#{node['cluster']['chrony']['service']}]", :delayed
end

service node['cluster']['chrony']['service'] do
  reload_command chrony_reload_command
  action :nothing
end
