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

require 'digest'

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
    retries 5
    retry_delay 10
  end unless on_docker?
end

def setup_munge_head_node
  # Generate munge key or get it's value from secrets manager
  munge_key_manager 'manage_munge_key' do
    munge_key_secret_arn lazy {
      node['munge_key_secret_arn'] || node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :MungeKeySecretArn)
    }
  end
end

def update_munge_head_node
  munge_key_manager 'update_munge_key' do
    munge_key_secret_arn lazy { node['cluster']['config'].dig(:Scheduling, :SlurmSettings, :MungeKeySecretArn) }
    action :update_munge_key
    only_if { ::File.exist?(node['cluster']['previous_cluster_config_path']) && is_custom_munge_key_updated? }
  end
end

def setup_munge_key(shared_dir)
  bash 'get_munge_key' do
    user 'root'
    group 'root'
    code <<-MUNGE_KEY
      set -e
      # Copy munge key from shared dir
      cp #{shared_dir}/.munge/.munge.key /etc/munge/munge.key
      # Set ownership on the key
      chown #{node['cluster']['munge']['user']}:#{node['cluster']['munge']['group']} /etc/munge/munge.key
      # Enforce correct permission on the key
      chmod 0600 /etc/munge/munge.key
    MUNGE_KEY
    retries 5
    retry_delay 10
  end
end

def setup_munge_compute_node
  if kitchen_test?
    # FIXME: Mock munge key in shared directory.
    include_recipe 'aws-parallelcluster-slurm::mock_munge_key'
  end
  setup_munge_key(node['cluster']['shared_dir'])
  enable_munge_service
end

def setup_munge_login_node
  setup_munge_key(node['cluster']['shared_dir_login'])
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

def get_target_group_name(cluster_name, pool_name)
  partial_cluster_name = cluster_name[0..6]
  partial_pool_name = pool_name[0..6]
  combined_name = cluster_name + pool_name
  hash_value = Digest::SHA256.hexdigest(combined_name)[0..15]
  "#{partial_cluster_name}-#{partial_pool_name}-#{hash_value}"
end

def validate_file_hash(file_path, expected_hash)
  hash_function = yield
  checksum = hash_function.file(file_path).hexdigest
  if checksum != expected_hash
    raise "Downloaded file #{file_path} checksum #{checksum} does not match expected checksum #{expected_hash}"
  end
end

def validate_file_md5_hash(file_path, expected_hash)
  validate_file_hash(file_path, expected_hash) do
    require 'digest'
    Digest::MD5
  end
end

def wait_cluster_ready
  return if on_docker? || kitchen_test? && !node['interact_with_ddb']
  execute "Check cluster readiness" do
    command "#{cookbook_virtualenv_path}/bin/python #{node['cluster']['scripts_dir']}/head_node_checks/check_cluster_ready.py" \
              " --cluster-name #{node['cluster']['stack_name']}" \
              " --table-name parallelcluster-#{node['cluster']['stack_name']}" \
              " --config-version #{node['cluster']['cluster_config_version']}" \
              " --region #{node['cluster']['region']}"
    timeout 30
    retries 10
    retry_delay 90
  end
end

def wait_static_fleet_running
  ruby_block "wait for static fleet capacity" do
    block do
      require 'chef/mixin/shell_out'
      require 'shellwords'
      require 'json'

      def check_for_protected_mode(fleet_status_command) # rubocop:disable Lint/NestedMethodDefinition
        begin
          cluster_state_json = shell_out!("/bin/bash -c #{fleet_status_command}").stdout.strip
          cluster_state = JSON.load(cluster_state_json)
        rescue
          Chef::Log.warn("Unable to get compute fleet status")
          return
        end

        Chef::Log.info("Compute fleet status is empty") if cluster_state.empty?
        return if cluster_state.empty?

        raise "Cluster has been set to PROTECTED mode due to failures detected in static node provisioning" if cluster_state["status"] == "PROTECTED"
      end

      fleet_status_command = Shellwords.escape(
        "/usr/local/bin/get-compute-fleet-status.sh"
      )
      # Example output for sinfo
      # $ /opt/slurm/bin/sinfo -N -h -o '%N %t'
      # ondemand-dy-c52xlarge-1 idle~
      # ondemand-dy-c52xlarge-2 idle~
      # spot-dy-c5xlarge-1 idle~
      # spot-st-t2large-1 down
      # spot-st-t2large-2 idle
      # capacity-block-st-t2micro-1 maint
      # capacity-block-dy-t2micro-1 maint
      is_fleet_ready_command = Shellwords.escape(
        "set -o pipefail && #{node['cluster']['slurm']['install_dir']}/bin/sinfo -N -h -o '%N %t' | { grep -E '^[a-z0-9\\-]+\\-st\\-[a-z0-9\\-]+\\-[0-9]+ .*' || true; } | { grep -v -E '(idle|alloc|mix|maint)$' || true; }"
      )
      until shell_out!("/bin/bash -c #{is_fleet_ready_command}").stdout.strip.empty?
        check_for_protected_mode(fleet_status_command)

        Chef::Log.info("Waiting for static fleet capacity provisioning")
        sleep(15)
      end
      Chef::Log.info("Static fleet capacity is ready")
    end
  end
end
