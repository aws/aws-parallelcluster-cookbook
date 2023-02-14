# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.



control 'dns_domain_configured' do
  title "Checks that the DNS search domain is configured"

  dns_domain_string = 'test-domain'
  config_file = '/etc/dhcp/dhclient.conf'
  if os_properties.debian_family?
    config_file = '/etc/systemd/resolved.conf'
  end

  describe file(config_file) do
    it { should exist }
    its('content') do
      should match(dns_domain_string)
    end
  end
end
