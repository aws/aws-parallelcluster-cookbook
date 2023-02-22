# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: network_interfaces
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

def network_interface_macs(token)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs")
  res = get_metadata_with_token(token, uri)
  res.delete("/").split("\n")
end

def device_name(mac)
  cmd = Mixlib::ShellOut.new("ip -o link | grep #{mac} | awk '{print substr($2, 1, length($2) -1)}'")
  cmd.run_command
  cmd.stdout.delete("\n")
end

def device_ip(mac, token)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/local-ipv4s")
  get_metadata_with_token(token, uri)
end

def gateway_address
  cmd = Mixlib::ShellOut.new("ip r | grep default | head -n 1 | awk '{print $3}'")
  cmd.run_command
  cmd.stdout.delete("\n")
end

def subnet_cidr_block(mac, token)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}/subnet-ipv4-cidr-block")
  get_metadata_with_token(token, uri)
end

def cidr_prefix_length(mac, token)
  subnet_cidr_block(mac, token).split("/")[1]
end

def cidr_to_netmask(cidr)
  require 'ipaddr'
  IPAddr.new('255.255.255.255').mask(cidr).to_s
end

# generate the token for retrieving IMDSv2 metadata
token = get_metadata_token
macs = network_interface_macs(token)
log "macs: #{macs}"

if macs.length > 1

  cookbook_file 'configure_nw_interface.sh' do
    source 'network_interfaces/configure_nw_interface.sh'
    path '/tmp/configure_nw_interface.sh'
    user 'root'
    group 'root'
    mode '0644'
  end

  # Configure nw interfaces
  macs.each_with_index do |mac, device_number|
    device_name = device_name(mac)
    gw_ip_address = gateway_address
    device_ip_address = device_ip(mac, token)
    cidr_prefix_length = cidr_prefix_length(mac, token)
    netmask = cidr_to_netmask(cidr_prefix_length)
    cidr_block = subnet_cidr_block(mac, token)
    log "device_number: #{device_number}, device_name: #{device_name}, device_ip_address: #{device_ip_address}"

    execute 'configure_nw_interface' do
      user 'root'
      group 'root'
      cwd "/tmp"
      environment(
        'DEVICE_NAME' => device_name,
        'DEVICE_NUMBER' => "#{device_number}",
        'GW_IP_ADDRESS' => gw_ip_address,
        'DEVICE_IP_ADDRESS' => device_ip_address,
        'CIDR_PREFIX_LENGTH' => cidr_prefix_length,
        'NETMASK' => netmask,
        'CIDR_BLOCK' => cidr_block
      )

      command 'sh /tmp/configure_nw_interface.sh'
    end
  end

  # Apply configuration
  reload_network_config
end
