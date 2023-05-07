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

require 'chef/mixin/shell_out'
require 'net/http'
require 'timeout'

#
# Wait 60 seconds for the block device to be ready
#
def wait_for_block_dev(path)
  Timeout.timeout(60) do
    until ::File.blockdev?(path)
      Chef::Log.info("device #{path} not ready - sleeping 5s")
      sleep(5)
      rescan_pci
    end
    Chef::Log.info("device #{path} is ready")
  end
end

#
# Rescan the PCI bus to discover newly added volumes.
#
def rescan_pci
  Mixlib::ShellOut.new("echo 1 > /sys/bus/pci/rescan").run_command
end

#
# Format a block device using the EXT4 file system if it is not already
# formatted.
#
def setup_disk(path)
  dev = ::File.readlink(path)
  full_path = ::File.absolute_path(dev, ::File.dirname(path))

  fs_type = get_fs_type(full_path)
  if fs_type.nil?
    Mixlib::ShellOut.new("mkfs.ext4 #{full_path}").run_command
    fs_type = 'ext4'
  end

  fs_type
end

#
# Checks if device is partitioned; if yes returns pt type
#
def get_pt_type(device)
  fs_check = Mixlib::ShellOut.new("blkid -c /dev/null #{device}")
  fs_check.run_command
  match = fs_check.stdout.match(/\sPTTYPE="(.*?)"/)
  match = '' if match.nil?

  Chef::Log.info("Partition type for device #{device}: #{match[1]}")
  match[1]
end

#
# Check if block device has a fileystem
#
def get_fs_type(device)
  fs_check = Mixlib::ShellOut.new("blkid -c /dev/null #{device}")
  fs_check.run_command
  match = fs_check.stdout.match(/\sTYPE="(.*?)"/)
  match = '' if match.nil?

  Chef::Log.info("File system type for device #{device}: #{match[1]}")
  match[1]
end

#
# Gets the uuid of a device
#
def get_uuid(device)
  Chef::Log.info("Getting uuid for device: #{device}")
  fs_check = Mixlib::ShellOut.new("blkid -c /dev/null #{device}")
  fs_check.run_command
  match = fs_check.stdout.match(/\sUUID="(.*?)"/)
  match = '' if match.nil?
  Chef::Log.info("uuid for device: #{device} is #{match[1]}")
  match[1]
end

#
# Returns the first partition of a device, provided via sym link
#
def get_1st_partition(device)
  # Resolves the real device name (ex. /dev/sdg)
  Chef::Log.info("Getting 1st partition for device: #{device}")
  fs_check = Mixlib::ShellOut.new("lsblk -ln -o Name #{device}|awk 'NR==2'")
  fs_check.run_command
  partition = "/dev/#{fs_check.stdout.strip}"
  Chef::Log.info("1st partition for device: #{device} is: #{partition}")
  partition
end

#
# Get vpc-ipv4-cidr-blocks
#
def get_vpc_ipv4_cidr_blocks(eth0_mac)
  vpc_ipv4_cidr_blocks = node['ec2']['network_interfaces_macs'][eth0_mac.downcase]['vpc_ipv4_cidr_blocks']
  vpc_ipv4_cidr_blocks.split("\n")
end

def pip_install_package(package, version)
  command = Mixlib::ShellOut.new("pip install #{package}==#{version}").run_command
  Chef::Application.fatal!("Failed to install package #{package} #{version}", command.exitstatus) unless command.exitstatus.zero?
end

def ignore_failure(lookup)
  resource = resources(lookup)
  if resource.nil?
    Chef::Log.warn("Can't find resource to ignore: #{lookup}")
  else
    Chef::Log.info("Ignore failure for resource: #{lookup}")
    resource.ignore_failure(true)
  end
end

#
# Check if the instance has a GPU
#
def graphic_instance?
  has_gpu = Mixlib::ShellOut.new("lspci | grep -i -o 'NVIDIA'")
  has_gpu.run_command

  !has_gpu.stdout.strip.empty?
end

#
# Check if Nvidia driver is installed
#
def nvidia_installed?
  nvidia_installed = ::File.exist?('/usr/bin/nvidia-smi')
  Chef::Log.warn("Nvidia driver is not installed") unless nvidia_installed
  nvidia_installed
end

#
# Check if the AMI is bootstrapped
#
def ami_bootstrapped?
  version = ''
  bootstrapped_file = '/opt/parallelcluster/.bootstrapped'
  current_version = "aws-parallelcluster-cookbook-#{node['cluster']['parallelcluster-cookbook-version']}"

  if ::File.exist?(bootstrapped_file)
    version = IO.read(bootstrapped_file).chomp
    Chef::Log.info("Detected bootstrap file #{version}")
    if version != current_version
      raise "This AMI was created with #{version}, but is trying to be used with #{current_version}. " \
            "Please either use an AMI created with #{current_version} or change your ParallelCluster to #{version}"
    end
  end

  version != '' && (node['cluster']['skip_install_recipes'] == 'yes' || node['cluster']['skip_install_recipes'] == true)
end

#
# Check if OS type specified by the user is the same as the OS identified by Ohai
#
def validate_os_type
  case node['platform']
  when 'ubuntu'
    current_os = "ubuntu#{node['platform_version'].tr('.', '')}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  when 'amazon'
    current_os = "alinux#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  when 'centos'
    current_os = "centos#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  when 'redhat'
    current_os = "rhel#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cluster']['base_os']) if node['cluster']['base_os'] != current_os
  end
end

#
# Raise error if OS types do not match
#
def raise_os_not_match(current_os, specified_os)
  raise "The custom AMI you have provided uses the #{current_os} OS. " \
        "However, the base_os specified in your config file is #{specified_os}. " \
        "Please either use an AMI with the #{specified_os} OS or update the base_os " \
        "setting in your configuration file to #{current_os}."
end

# Check if this platform supports intel's HPC platform
#
def platform_supports_intel_hpc_platform?
  node['platform'] == 'centos'
end

def kernel_release
  ENV['KERNEL_RELEASE'] || default['cluster']['kernel_release']
end

# Add an external package repository to the OS's package manager
# NOTE: This helper function defines a Chef resource function to be executed at Converge time
def add_package_repository(repo_name, baseurl, gpgkey, distribution)
  case node['platform_family']
  when 'rhel', 'amazon'
    yum_repository repo_name do
      baseurl baseurl
      gpgkey gpgkey
      retries 3
      retry_delay 5
    end
  when 'debian'
    apt_repository repo_name do
      uri          baseurl
      key          gpgkey
      distribution distribution
      retries 3
      retry_delay 5
    end
    apt_update 'update' do
      retries 3
      retry_delay 5
    end
  else
    raise "platform not supported: #{node['platform_family']}"
  end
end

# Remove an external package repository from the OS's package manager
# NOTE: This helper function defines a Chef resource function to be executed at Converge time
def remove_package_repository(repo_name)
  case node['platform_family']
  when 'rhel', 'amazon'
    yum_repository repo_name do
      action :remove
    end
  when 'debian'
    apt_repository repo_name do
      action :remove
    end
    apt_update
  else
    raise "platform not supported: #{node['platform_family']}"
  end
end

# Get number of nv switches
def get_nvswitches
  # NVSwitch device id is 10de:1af1
  nvswitch_check = Mixlib::ShellOut.new("lspci -d 10de:1af1 | wc -l")
  nvswitch_check.run_command
  nvswitch_check.stdout.strip.to_i
end

def get_system_users
  cmd = Mixlib::ShellOut.new("cat /etc/passwd | cut -d: -f1")
  cmd.run_command
  cmd.stdout.split(/\n+/)
end

def run_command(command)
  Mixlib::ShellOut.new(command).run_command.stdout.strip
end

def raise_and_write_chef_error(raise_message, chef_error = nil)
  unless chef_error
    chef_error = raise_message
  end
  Mixlib::ShellOut.new("echo '#{chef_error}' > /var/log/parallelcluster/bootstrap_error_msg").run_command
  raise raise_message
end

# Verify if Scheduling section of cluster configuration and compute node bootstrap_timeout have been updated
def are_queues_updated?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config["Scheduling"] != previous_config["Scheduling"] or is_compute_node_bootstrap_timeout_updated?(previous_config, config)
end

# Verify if CustomSlurmSettings has been updated in the config
def are_bulk_custom_slurm_settings_updated?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config["Scheduling"]["SlurmSettings"]["CustomSlurmSettings"] != previous_config["Scheduling"]["SlurmSettings"]["CustomSlurmSettings"]
end

def are_mount_or_unmount_required?
  require 'json'
  change_set = JSON.load_file("#{node['cluster']['shared_dir']}/change-set.json")
  change_set["changeSet"].each do |change|
    next unless change["updatePolicy"] == "SHARED_STORAGE_UPDATE_POLICY"

    return true
  end
  Chef::Log.info("No shared storages operation required.")
  false
end

def evaluate_compute_bootstrap_timeout(config)
  config.dig("DevSettings", "Timeouts", "ComputeNodeBootstrapTimeout") or 1800
end

def is_compute_node_bootstrap_timeout_updated?(previous_config, config)
  evaluate_compute_bootstrap_timeout(previous_config) != evaluate_compute_bootstrap_timeout(config)
end

def raise_command_error(command, cmd)
  Chef::Log.error("Error while executing command (#{command})")
  raise "#{cmd.stderr.strip}"
end

def execute_command(command, user = "root", timeout = 300, raise_on_error = true)
  cmd = Mixlib::ShellOut.new(command, user: user, timeout: timeout)
  cmd.run_command
  raise_command_error(command, cmd) if raise_on_error && cmd.error?
  cmd.stdout.strip
end

def is_slurm_database_updated?
  require 'yaml'
  config = YAML.safe_load(File.read(node['cluster']['cluster_config_path']))
  previous_config = YAML.safe_load(File.read(node['cluster']['previous_cluster_config_path']))
  config["Scheduling"]["SlurmSettings"]["Database"] != previous_config["Scheduling"]["SlurmSettings"]["Database"]
end

# Parse an ARN.
# ARN format: arn:PARTITION:SERVICE:REGION:ACCOUNT_ID:RESOURCE.
# ARN examples:
#   1. arn:aws:secretsmanager:eu-west-1:12345678910:secret:PasswordName
#   2. arn:aws:ssm:eu-west-1:12345678910:parameter/PasswordName
def parse_arn(arn_string)
  parts = arn_string.nil? ? [] : arn_string.split(':', 6)
  raise TypeError if parts.size < 6

  {
    partition: parts[1],
    service: parts[2],
    region: parts[3],
    account_id: parts[4],
    resource: parts[5],
  }
end

def network_interface_macs(token)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs")
  res = get_metadata_with_token(token, uri)
  res.delete("/").split("\n")
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
