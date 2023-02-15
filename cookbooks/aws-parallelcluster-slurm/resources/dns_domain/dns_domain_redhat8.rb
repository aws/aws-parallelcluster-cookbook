# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :dns_domain, platform: 'redhat' do |node|
  node['platform_version'].to_i == 8
end
unified_mode true

default_action :configure

# Configure custom dns domain (only if defined) by appending the Route53 domain created within the cluster
# ($CLUSTER_NAME.pcluster) and be listed as a "search" domain in the resolv.conf file.
action :configure do
  return if virtualized?

  Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to /etc/dhcp/dhclient.conf")
  # Configure dhclient to automatically append Route53 search domain in resolv.conf
  # - on CentOS7 and Alinux2 resolv.conf is managed by NetworkManager + dhclient,
  replace_or_add "append Route53 search domain in /etc/dhcp/dhclient.conf" do
    path "/etc/dhcp/dhclient.conf"
    pattern "append domain-name*"
    line "append domain-name \" #{node['cluster']['dns_domain']}\";"
  end

  restart_network_service
end
