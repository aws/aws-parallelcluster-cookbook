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

action :setup do
  package "hostname" do
    retries 3
    retry_delay 5
  end
end

action :configure do
  return if on_docker?
  action_update_search_domain
  network_service 'Restart network service'
end

action :update_search_domain do
  Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to #{search_domain_config_path}")
  replace_or_add "append Route53 search domain in #{search_domain_config_path}" do
    path search_domain_config_path
    pattern append_pattern
    line append_line
  end
end
