# frozen_string_literal: true

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

#
# Retrieve compute nodename from file
#
def slurm_nodename
  slurm_nodename_file = "#{node['cluster']['slurm_plugin_dir']}/slurm_nodename"

  IO.read(slurm_nodename_file).chomp
end

#
# Retrieve compute and head node info from dynamo db (Slurm only)
#
def dynamodb_info(aws_connection_timeout_seconds: 30, aws_read_timeout_seconds: 60, shell_timout_seconds: 300)
  output = Mixlib::ShellOut.new("#{cookbook_virtualenv_path}/bin/aws dynamodb " \
                      "--region #{node['cluster']['region']} query --table-name #{node['cluster']['slurm_ddb_table']} " \
                      "--index-name InstanceId --key-condition-expression 'InstanceId = :instanceid' " \
                      "--expression-attribute-values '{\":instanceid\": {\"S\":\"#{node['ec2']['instance_id']}\"}}' " \
                      "--projection-expression 'Id' " \
                      "--cli-connect-timeout #{aws_connection_timeout_seconds} " \
                      "--cli-read-timeout #{aws_read_timeout_seconds} " \
                      "--output text --query 'Items[0].[Id.S]'",
                                user: 'root',
                                timeout: shell_timout_seconds).run_command.stdout.strip

  raise "Failed when retrieving Compute info from DynamoDB" if output.nil? || output.empty? || output == "None"

  slurm_nodename = output

  Chef::Log.info("Retrieved Slurm nodename is: #{slurm_nodename}")

  slurm_nodename
end

#
# Verify if a given node name is a static node or a dynamic one (Slurm only)
#
def is_static_node?(nodename)
  # Match queue1-st-compute2-1 or queue1-st-compute2-[1-1000] format
  match = nodename.match(/^([a-z0-9\-]+)-(st|dy)-([a-z0-9\-]+)-\[?\d+[\-\d+]*\]?$/)
  raise "Failed when parsing Compute nodename: #{nodename}" if match.nil?

  match[2] == "st"
end

def enable_munge_service
  service "munge" do
    supports restart: true
    action %i(enable start)
  end
end

def setup_munge_head_node
  # Generate munge key
  bash 'generate_munge_key' do
    not_if { ::File.exist?('/etc/munge/munge.key') }
    user node['cluster']['munge']['user']
    group node['cluster']['munge']['group']
    cwd '/tmp'
    code <<-HEAD_CREATE_MUNGE_KEY
      set -e
      # Generates munge key in /etc/munge/munge.key
      /usr/sbin/mungekey --verbose
      # Enforce correct permission on the key
      chmod 0600 /etc/munge/munge.key
    HEAD_CREATE_MUNGE_KEY
  end

  enable_munge_service
  share_munge_head_node
end

def share_munge_head_node
  # Share munge key
  bash 'share_munge_key' do
    user 'root'
    group 'root'
    code <<-HEAD_SHARE_MUNGE_KEY
      set -e
      mkdir -p /home/#{node['cluster']['cluster_user']}/.munge
      # Copy key to shared dir
      cp /etc/munge/munge.key /home/#{node['cluster']['cluster_user']}/.munge/.munge.key
    HEAD_SHARE_MUNGE_KEY
  end
end

def setup_munge_compute_node
  # Get munge key
  bash 'get_munge_key' do
    user 'root'
    group 'root'
    code <<-COMPUTE_MUNGE_KEY
      set -e
      # Copy munge key from shared dir
      cp /home/#{node['cluster']['cluster_user']}/.munge/.munge.key /etc/munge/munge.key
      # Set ownership on the key
      chown #{node['cluster']['munge']['user']}:#{node['cluster']['munge']['group']} /etc/munge/munge.key
      # Enforce correct permission on the key
      chmod 0600 /etc/munge/munge.key
    COMPUTE_MUNGE_KEY
  end

  enable_munge_service
end

def get_primary_ip
  primary_ip = node['ec2']['local_ipv4']

  # TODO: We should use instance info stored in node['ec2'] by Ohai, rather than calling IMDS.
  # We cannot use MAC related data because we noticed a mismatch in the info returned by Ohai and IMDS.
  # In particular, the data returned by Ohai is missing the 'network-card' information.
  token = get_metadata_token
  macs = network_interface_macs(token)

  if macs.length > 1
    macs.each do |mac|
      mac_metadata_uri = "http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{mac}"
      device_number = get_metadata_with_token(token, URI("#{mac_metadata_uri}/device-number"))
      network_card = get_metadata_with_token(token, URI("#{mac_metadata_uri}/network-card"))
      next unless device_number == '0' && network_card == '0'

      primary_ip = get_metadata_with_token(token, URI("#{mac_metadata_uri}/local-ipv4s"))
      break
    end
  end

  primary_ip
end
