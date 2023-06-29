# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

provides :dns_domain, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_dns_domain_common'

def search_domain_config_path
  # Configure resolved to automatically append Route53 search domain in resolv.conf.
  # On Amazon Linux 2023 resolv.conf is managed by systemd-resolved.
  '/etc/systemd/resolved.conf'
end

def append_pattern
  'Domains=*'
end

def append_line
  "Domains=#{node['cluster']['dns_domain']}"
end
