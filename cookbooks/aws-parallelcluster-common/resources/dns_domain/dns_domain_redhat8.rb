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

default_action :setup

use 'partial/_dns_search_domain_redhat'

action :setup do
  package "hostname" do
    retries 3
    retry_delay 5
  end
end
# Configure custom dns domain (only if defined) by appending the Route53 domain created within the cluster
# ($CLUSTER_NAME.pcluster) and be listed as a "search" domain in the resolv.conf file.
action :configure do
  return if virtualized?

  # On RHEL8 dhclient is not enabled by default
  # Put pcluster version of NetworkManager.conf in place
  # dhcp = dhclient needs to be added under [main] section to enable dhclient
  # https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/considerations_in_adopting_rhel_8/networking_considerations-in-adopting-rhel-8#dhcp_plugin_networking
  cookbook_file 'NetworkManager.conf' do
    path '/etc/NetworkManager/NetworkManager.conf'
    source 'dns_domain/NetworkManager.conf'
    user 'root'
    group 'root'
    mode '0644'
  end

  action_update_search_domain_redhat

  network_service 'Restart network service'
end
