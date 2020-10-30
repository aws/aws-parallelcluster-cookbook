# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: dns_config
#
# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
if node['cfncluster']['cfn_scheduler'] == 'slurm' && node['cfncluster']['use_private_hostname'] == 'false'
  # Heterogeneous Instance Type

  if !node['cfncluster']['cfn_dns_domain'].nil? && !node['cfncluster']['cfn_dns_domain'].empty?
    # Configure custom dns domain (only if defined) by appending the Route53 domain created within the cluster
    # ($CLUSTER_NAME.pcluster) and be listed as a "search" domain in the resolv.conf file.
    if platform?('ubuntu') && node['platform_version'] == "18.04"

      Chef::Log.info("Appending search domain '#{node['cfncluster']['cfn_dns_domain']}' to /etc/systemd/resolved.conf")
      # Configure resolved to automatically append Route53 search domain in resolv.conf.
      # On Ubuntu18 resolv.conf is managed by systemd-resolved.
      replace_or_add "append Route53 search domain in /etc/systemd/resolved.conf" do
        path "/etc/systemd/resolved.conf"
        pattern "Domains=*"
        line "Domains=#{node['cfncluster']['cfn_dns_domain']}"
      end
    else

      Chef::Log.info("Appending search domain '#{node['cfncluster']['cfn_dns_domain']}' to /etc/dhcp/dhclient.conf")
      # Configure dhclient to automatically append Route53 search domain in resolv.conf
      # - on CentOS7, Alinux and Alinux2 resolv.conf is managed by NetworkManager + dhclient,
      # - on Ubuntu16 by networking + dhclient
      # - on CentOS8 by NetworkManager (but dhclient is not enabled by default)
      replace_or_add "append Route53 search domain in /etc/dhcp/dhclient.conf" do
        path "/etc/dhcp/dhclient.conf"
        pattern "append domain-name*"
        line "append domain-name \" #{node['cfncluster']['cfn_dns_domain']}\";"
      end

      if platform?('centos') && node['platform_version'].to_i == 8
        # On CentOS8 dhclient is not enabled by default
        # Put pcluster version of NetworkManager.conf in place
        # dhcp = dhclient needs to be added under [main] section to enable dhclient
        cookbook_file 'NetworkManager.conf' do
          path '/etc/NetworkManager/NetworkManager.conf'
          user 'root'
          group 'root'
          mode '0644'
        end
      end
    end
    restart_network_service
  end

  if node['cfncluster']['cfn_node_type'] == "ComputeFleet"
    # For compute node retrieve assigned hostname from DynamoDB and configure it
    # - hostname: $QUEUE-st-$INSTANCE_TYPE_1-[1-$MIN1]
    # - fqdn: $QUEUE-st-$INSTANCE_TYPE_1-[1-$MIN1].$CLUSTER_NAME.pcluster
    ruby_block "retrieve assigned hostname" do
      block do
        assigned_hostname = hit_slurm_nodename
        node.force_default['cfncluster']['assigned_short_hostname'] = assigned_hostname.to_s

        if node['cfncluster']['cfn_dns_domain'].nil? || node['cfncluster']['cfn_dns_domain'].empty?
          # Use domain from DHCP
          dhcp_domain = node['ec2']['local_hostname'].split('.', 2).last
          node.force_default['cfncluster']['assigned_hostname'] = "#{assigned_hostname}.#{dhcp_domain}"
        else
          # Use cluster domain
          node.force_default['cfncluster']['assigned_hostname'] = "#{assigned_hostname}.#{node['cfncluster']['cfn_dns_domain']}"
        end
      end
      retries 5
      retry_delay 3
    end

  else
    # Head node
    node.force_default['cfncluster']['assigned_hostname'] = node['ec2']['local_hostname']
    node.force_default['cfncluster']['assigned_short_hostname'] = node['ec2']['local_hostname'].split('.')[0].to_s
  end

else
  # Single Instance Type
  node.force_default['cfncluster']['assigned_hostname'] = node['ec2']['local_hostname']
  node.force_default['cfncluster']['assigned_short_hostname'] = node['ec2']['local_hostname'].split('.')[0].to_s
end

# Configure short hostname
hostname "set short hostname" do
  compile_time false
  hostname(lazy { node['cfncluster']['assigned_short_hostname'] })
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
  line(lazy { "#{node['ec2']['local_ipv4']} #{node['cfncluster']['assigned_hostname']} #{node['cfncluster']['assigned_short_hostname']}" })
  notifies :reload, "ohai[reload_hostname]"
end

