# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

provides :network_service, platform: 'amazon' do |node|
  node['platform_version'].to_i == 2023
end

use 'partial/_network_service'
use 'partial/_network_service_redhat_based'

def network_service_name
  'systemd-networkd'
end

action :restart do
  log "Restarting 'systemd-networkd systemd-resolved' service, platform #{node['platform']} '#{node['platform_version']}'"

  execute "Reload system configuration files before restarting services" do
    command "systemctl daemon-reload"
  end

  %w(systemd-networkd systemd-resolved).each do |service_name|
    # Restart systemd-networkd to load configuration about NICs.
    # Restart systemd-resolved to load configuration about DNS.
    service service_name do
      action :restart
      ignore_failure true
    end
  end
end
