# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

action :configure do
  if node['cluster']['node_type'] == "HeadNode"
    node.force_override['nfs']['threads'] = node['cluster']['nfs']['threads']
    render_server_config

    service node['nfs']['service']['server'] do
      action %i(enable start)
      supports restart: true
      retries 5
      retry_delay 10
    end unless on_docker?
  else
    service node['nfs']['service']['server'] do
      action %i(stop disable)
    end unless on_docker?
  end
end

action_class do
  def render_server_config
    server_service = node['nfs']['service']['server']

    if conf_d_supported?
      directory '/etc/nfs.conf.d' do
        mode '0755'
      end

      template '/etc/nfs.conf.d/parallelcluster-nfs.conf' do
        source 'nfs/parallelcluster-nfs.conf.erb'
        cookbook 'aws-parallelcluster-environment'
        mode '0644'
        notifies :restart, "service[#{server_service}]", :delayed unless on_docker?
      end
    else
      template '/etc/nfs.conf' do
        source 'nfs/nfs.conf.erb'
        cookbook 'aws-parallelcluster-environment'
        mode '0644'
        notifies :restart, "service[#{server_service}]", :delayed unless on_docker?
      end
    end
  end

  # /etc/nfs.conf.d/*.conf auto-include requires nfs-utils >= ~2.4.1. The only supported platform
  # older than that is RHEL/Rocky 8 (nfs-utils 2.3.3), where we render /etc/nfs.conf directly.
  def conf_d_supported?
    !(platform_family?('rhel') && node['platform_version'].to_i == 8)
  end
end
