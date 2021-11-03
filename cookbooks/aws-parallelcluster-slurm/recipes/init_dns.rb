# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster-slurm
# Recipe:: init_dns
#
# Copyright 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# It is possible to restore the SIT behaviour by setting the use_private_hostname = true as extra_json parameter
if node['cluster']['scheduler'] == 'slurm' && node['cluster']['use_private_hostname'] == 'false'
  # Heterogeneous Instance Type

  if !node['cluster']['dns_domain'].nil? && !node['cluster']['dns_domain'].empty?
    # Configure custom dns domain (only if defined) by appending the Route53 domain created within the cluster
    # ($CLUSTER_NAME.pcluster) and be listed as a "search" domain in the resolv.conf file.
    if platform?('ubuntu')

      Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to /etc/systemd/resolved.conf")
      # Configure resolved to automatically append Route53 search domain in resolv.conf.
      # On Ubuntu18 resolv.conf is managed by systemd-resolved.
      replace_or_add "append Route53 search domain in /etc/systemd/resolved.conf" do
        path "/etc/systemd/resolved.conf"
        pattern "Domains=*"
        line "Domains=#{node['cluster']['dns_domain']}"
      end
    else

      Chef::Log.info("Appending search domain '#{node['cluster']['dns_domain']}' to /etc/dhcp/dhclient.conf")
      # Configure dhclient to automatically append Route53 search domain in resolv.conf
      # - on CentOS7 and Alinux2 resolv.conf is managed by NetworkManager + dhclient,
      replace_or_add "append Route53 search domain in /etc/dhcp/dhclient.conf" do
        path "/etc/dhcp/dhclient.conf"
        pattern "append domain-name*"
        line "append domain-name \" #{node['cluster']['dns_domain']}\";"
      end
    end
    restart_network_service
  end

  if node['cluster']['node_type'] == "ComputeFleet"
    # For compute node retrieve assigned hostname from DynamoDB and configure it
    # - hostname: $QUEUE-st-$INSTANCE_TYPE_1-[1-$MIN1]
    # - fqdn: $QUEUE-st-$INSTANCE_TYPE_1-[1-$MIN1].$CLUSTER_NAME.pcluster
    ruby_block "retrieve assigned hostname" do
      block do
        assigned_hostname = hit_slurm_nodename
        node.force_default['cluster']['assigned_short_hostname'] = assigned_hostname.to_s

        if node['cluster']['dns_domain'].nil? || node['cluster']['dns_domain'].empty?
          # Use domain from DHCP
          dhcp_domain = node['ec2']['local_hostname'].split('.', 2).last
          node.force_default['cluster']['assigned_hostname'] = "#{assigned_hostname}.#{dhcp_domain}"
        else
          # Use cluster domain
          node.force_default['cluster']['assigned_hostname'] = "#{assigned_hostname}.#{node['cluster']['dns_domain']}"
        end
      end
      retries 5
      retry_delay 3
    end

  else
    # Head node
    node.force_default['cluster']['assigned_hostname'] = node['ec2']['local_hostname']
    node.force_default['cluster']['assigned_short_hostname'] = node['ec2']['local_hostname'].split('.')[0].to_s
  end

else
  # Single Instance Type
  node.force_default['cluster']['assigned_hostname'] = node['ec2']['local_hostname']
  node.force_default['cluster']['assigned_short_hostname'] = node['ec2']['local_hostname'].split('.')[0].to_s
end

# Configure short hostname
hostname "set short hostname" do
  compile_time false
  hostname(lazy { node['cluster']['assigned_short_hostname'] })
end

# Resource to be called to reload ohai attributes after /etc/hosts update
ohai 'reload_hostname' do
  plugin 'hostname'
  action :nothing
end

# Configure fqdn in /etc/hosts
replace_or_add "set fqdn in the /etc/hosts" do
  path "/etc/hosts"
  pattern "^#{node['ec2']['local_ipv4']}\s+"
  line(lazy { "#{node['ec2']['local_ipv4']} #{node['cluster']['assigned_hostname']} #{node['cluster']['assigned_short_hostname']}" })
  notifies :reload, "ohai[reload_hostname]"
end
