# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: init_dns
#
# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
        assigned_hostname = slurm_nodename
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
  primary_ip = ""
  # token = get_metadata_token
  # generate the token for retrieving IMDSv2 metadata
  token_uri = URI("http://169.254.169.254/latest/api/token")
  token_request = Net::HTTP::Put.new(token_uri)
  token_request["X-aws-ec2-metadata-token-ttl-seconds"] = "300"
  res = Net::HTTP.new("169.254.169.254").request(token_request)
  token = res.body
  Chef::Log.info("token: '#{token}'")
  # macs = network_interface_macs(token)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs")
  # res = get_metadata_with_token(token, uri)
  request = Net::HTTP::Get.new(uri)
  request["X-aws-ec2-metadata-token"] = token
  res = Net::HTTP.new("169.254.169.254").request(request)
  metadata = res.body if res.code == '200'
  res = metadata
  macs = res.delete("/").split("\n")
  Chef::Log.info("macs: '#{macs}'")
  #log "macs: #{macs}"
  for mac in macs
    uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/device-number")
    #device_number = get_metadata_with_token(token, uri)
    request = Net::HTTP::Get.new(uri)
    request["X-aws-ec2-metadata-token"] = token
    res = Net::HTTP.new("169.254.169.254").request(request)
    metadata = res.body if res.code == '200'
    device_number = metadata
    Chef::Log.info("for mac '#{mac}' the device-number is '#{device_number}'")
    uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/network-card")
    #network_card = get_metadata_with_token(token, uri)
    request = Net::HTTP::Get.new(uri)
    request["X-aws-ec2-metadata-token"] = token
    res = Net::HTTP.new("169.254.169.254").request(request)
    metadata = res.body if res.code == '200'
    network_card = metadata
    Chef::Log.info("for mac '#{mac}' the network-card is '#{network_card}'")
    if device_number == '0' && network_card == '0'
      uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/local-ipv4s")
      #primary_ip = get_metadata_with_token(token, uri)
      request = Net::HTTP::Get.new(uri)
      request["X-aws-ec2-metadata-token"] = token
      res = Net::HTTP.new("169.254.169.254").request(request)
      metadata = res.body if res.code == '200'
      primary_ip = metadata
      Chef::Log.info("the primary_ip is '#{primary_ip}' from the mac '#{mac}'")
      break
    end
  end
  pattern "^#{primary_ip}\s+"
  line(lazy { "#{primary_ip} #{node['cluster']['assigned_hostname'].chomp('.')} #{node['cluster']['assigned_short_hostname']}" })
  notifies :reload, "ohai[reload_hostname]"
end