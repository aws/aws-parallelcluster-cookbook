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

use 'partial/_dns_search_domain_redhat'

# Configure custom dns domain (only if defined) by appending the Route53 domain created within the cluster
# ($CLUSTER_NAME.pcluster) and be listed as a "search" domain in the resolv.conf file.
action :configure do
  return if virtualized?

  action_update_search_domain_redhat

  restart_network_service
end
