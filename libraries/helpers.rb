# frozen_string_literal: true

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
  token = get_metadata_token
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{eth0_mac.downcase}/vpc-ipv4-cidr-blocks")
  vpc_ipv4_cidr_blocks = get_metadata_with_token(token, uri)
  # Parse into array

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
# Check if the AMI is bootstrapped
#
def ami_bootstrapped?
  version = ''
  bootstrapped_file = '/opt/parallelcluster/.bootstrapped'
  current_version = "aws-parallelcluster-cookbook-#{node['cfncluster']['cfncluster-cookbook-version']}"

  if ::File.exist?(bootstrapped_file)
    version = IO.read(bootstrapped_file).chomp
    Chef::Log.info("Detected bootstrap file #{version}")
    if version != current_version
      raise "This AMI was created with #{version}, but is trying to be used with #{current_version}. " \
            "Please either use an AMI created with #{current_version} or change your ParallelCluster to #{version}"
    end
  end

  version != '' && (node['cfncluster']['skip_install_recipes'] == 'yes' || node['cfncluster']['skip_install_recipes'] == true)
end

#
# Check if OS type specified by the user is the same as the OS identified by Ohai
#
def validate_os_type
  case node['platform']
  when 'ubuntu'
    current_os = "ubuntu#{node['platform_version'].tr('.', '')}"
    raise_os_not_match(current_os, node['cfncluster']['cfn_base_os']) if node['cfncluster']['cfn_base_os'] != current_os
  when 'amazon'
    current_os = "alinux#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cfncluster']['cfn_base_os']) if node['cfncluster']['cfn_base_os'] != current_os
  when 'centos'
    current_os = "centos#{node['platform_version'].to_i}"
    raise_os_not_match(current_os, node['cfncluster']['cfn_base_os']) if node['cfncluster']['cfn_base_os'] != current_os
  end
end

#
# Raise error if OS types do not match
#
def raise_os_not_match(current_os, specified_os)
  raise "The custom AMI you have provided uses the #{current_os} OS." \
        "However, the base_os specified in your config file is #{specified_os}. " \
        "Please either use an AMI with the #{specified_os} OS or update the base_os " \
        "setting in your configuration file to #{current_os}."
end

#
# Retrieve head node ip and dns from file (HIT only)
#
def hit_head_node_info
  head_node_private_ip_file = "#{node['cfncluster']['slurm_plugin_dir']}/master_private_ip"
  head_node_private_dns_file = "#{node['cfncluster']['slurm_plugin_dir']}/master_private_dns"

  [IO.read(head_node_private_ip_file).chomp, IO.read(head_node_private_dns_file).chomp]
end

#
# Retrieve compute nodename from file (HIT only)
#
def hit_slurm_nodename
  slurm_nodename_file = "#{node['cfncluster']['slurm_plugin_dir']}/slurm_nodename"

  IO.read(slurm_nodename_file).chomp
end

#
# Retrieve compute and master node info from dynamo db (HIT only)
#
def hit_dynamodb_info
  require 'chef/mixin/shell_out'

  output = shell_out!("#{node['cfncluster']['cookbook_virtualenv_path']}/bin/aws dynamodb " \
    "--region #{node['cfncluster']['cfn_region']} query --table-name #{node['cfncluster']['cfn_ddb_table']} " \
    "--index-name InstanceId --key-condition-expression 'InstanceId = :instanceid' " \
    "--expression-attribute-values '{\":instanceid\": {\"S\":\"#{node['ec2']['instance_id']}\"}}' " \
    "--projection-expression 'Id,MasterPrivateIp,MasterHostname' " \
    "--output text --query 'Items[0].[Id.S,MasterPrivateIp.S,MasterHostname.S]'", user: 'root').stdout.strip

  raise "Failed when retrieving Compute info from DynamoDB" if output == "None"

  slurm_nodename, head_node_private_ip, head_node_private_dns = output.split(/\s+/)

  Chef::Log.info("Retrieved Slurm nodename is: #{slurm_nodename}")
  Chef::Log.info("Retrieved head node private ip: #{head_node_private_ip}")
  Chef::Log.info("Retrieved head node private dns: #{head_node_private_dns}")

  [slurm_nodename, head_node_private_ip, head_node_private_dns]
end

#
# Verify if a given node name is a static node or a dynamic one (HIT only)
#
def hit_is_static_node?(nodename)
  match = nodename.match(/^([a-z0-9\-]+)-(st|dy)-([a-z0-9]+)-\d+$/)
  raise "Failed when parsing Compute nodename: #{nodename}" if match.nil?

  match[2] == "st"
end

#
# Restart network service according to the OS.
# NOTE: This helper function defines a Chef resource function to be executed at Converge time
#
def restart_network_service
  network_service_name = value_for_platform(
    ['centos'] => {
      '>=8.0' => 'NetworkManager'
    },
    %w[ubuntu debian] => {
      '>=18.04' => 'systemd-resolved'
    },
    'default' => 'network'
  )
  Chef::Log.info("Restarting '#{network_service_name}' service, platform #{node['platform']} '#{node['platform_version']}'")
  service network_service_name.to_s do
    action %i[restart]
    ignore_failure true
  end
end

#
# Reload the network configuration according to the OS.
# NOTE: This helper function defines a Chef resource function to be executed at Converge time
#
def reload_network_config
  if node['platform'] == 'ubuntu'
    ruby_block "apply network configuration" do
      block do
        Mixlib::ShellOut.new("netplan apply").run_command
      end
    end
  else
    restart_network_service
  end
end

#
# Check if this is an ARM instance
#
def arm_instance?
  node['kernel']['machine'] == 'aarch64'
end

#
# Check if this platform supports intel's HPC platform
#
def platform_supports_intel_hpc_platform?
  node['platform'] == 'centos'
end

#
# Check if DCV is supported on this OS
#
def platform_supports_dcv?
  node['cfncluster']['dcv']['supported_os'].include?("#{node['platform']}#{node['platform_version'].to_i}")
end

#
# Check if Lustre is supported on this OS-architecture combination
#
def platform_supports_lustre_for_architecture?
  (arm_instance? && platform_supports_lustre_on_arm?) || !arm_instance?
end

#
# Check if Lustre is supported for ARM instances on this OS
#
def platform_supports_lustre_on_arm?
  [node['platform'] == 'ubuntu',
   node['platform'] == 'amazon',
   node['platform'] == 'centos']
end

def aws_domain
  # Set the aws domain name
  aws_domain = "amazonaws.com"
  aws_domain = "#{aws_domain}.cn" if node['cfncluster']['cfn_region'].start_with?("cn-")
  aws_domain
end

#
# Retrieve RHEL OS minor version from running kernel version
# The OS minor version is retrieved from the patch version of the running kernel
# following the mapping reported here https://access.redhat.com/articles/3078#RHEL7
# Method works for CentOS8 minor version >=2 and CentOS7 minor version >=7
#
def find_rhel_minor_version
  os_minor_version = ''

  if node['platform'] == 'centos'
    # kernel release is in the form 3.10.0-1127.8.2.el7.x86_64
    kernel_patch_version = node['kernel']['release'].match(/^\d+\.\d+\.\d+-(\d+)\..*$/)
    raise "Unable to retrieve the kernel patch version from #{node['kernel']['release']}." unless kernel_patch_version

    case node['platform_version'].to_i
    when 7
      os_minor_version = '7' if kernel_patch_version[1] >= '1062'
      os_minor_version = '8' if kernel_patch_version[1] >= '1127'
      os_minor_version = '9' if kernel_patch_version[1] >= '1160'
    when 8
      os_minor_version = '2' if kernel_patch_version[1] >= '193'
      os_minor_version = '3' if kernel_patch_version[1] >= '240'
      os_minor_version = '4' if kernel_patch_version[1] >= '305'
    else
      raise "CentOS version #{node['platform_version']} not supported."
    end
  end

  os_minor_version
end

# Return chrony service reload command
# Chrony doesn't support reload but only force-reload command
def chrony_reload_command
  case node['init_package']
  when 'init'
    chrony_reload_command = "service #{node['cfncluster']['chrony']['service']} force-reload"
  when 'systemd'
    chrony_reload_command = "systemctl force-reload #{node['cfncluster']['chrony']['service']}"
  else
    raise "Init package #{node['init_package']} not supported."

  end

  chrony_reload_command
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

# Check if EFA GDR is enabled (and supported) on this instance
def efa_gdr_enabled?
  config_value = node['cfncluster']['enable_efa_gdr']
  enabling_value = if node['cfncluster']['cfn_node_type'] == "ComputeFleet"
                     "compute"
                   else
                     "master"
                   end
  (config_value == enabling_value || config_value == "cluster") && graphic_instance?
end

# CentOS8 and alinux OSs currently not correctly supported by NFS cookbook
# Overwriting templates for node['nfs']['config']['server_template'] used by NFS cookbook for these OSs
# When running, NFS cookbook will use nfs.conf.erb templates provided in this cookbook to generate server_template
def overwrite_nfs_template?
  [
    node['platform'] == 'amazon',
    node['platform'] == 'centos' && node['platform_version'].to_i == 8
  ].any?
end

def enable_munge_service
  service "munge" do
    supports restart: true
    action %i[enable start]
  end
end

def setup_munge_head_node
  # Generate munge key
  bash 'generate_munge_key' do
    user 'munge'
    group 'munge'
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
      mkdir /home/#{node['cfncluster']['cfn_cluster_user']}/.munge
      # Copy key to shared dir
      cp /etc/munge/munge.key /home/#{node['cfncluster']['cfn_cluster_user']}/.munge/.munge.key
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
      cp /home/#{node['cfncluster']['cfn_cluster_user']}/.munge/.munge.key /etc/munge/munge.key
      # Set ownership on the key
      chown munge:munge /etc/munge/munge.key
      # Enforce correct permission on the key
      chmod 0600 /etc/munge/munge.key
    COMPUTE_MUNGE_KEY
  end

  enable_munge_service
end

def get_metadata_token
  # generate the token for retrieving IMDSv2 metadata
  token_uri = URI("http://169.254.169.254/latest/api/token")
  token_request = Net::HTTP::Put.new(token_uri)
  token_request["X-aws-ec2-metadata-token-ttl-seconds"] = "300"
  res = Net::HTTP.new("169.254.169.254").request(token_request)
  res.body
end

def get_metadata_with_token(token, uri)
  # get IMDSv2 metadata with token
  request = Net::HTTP::Get.new(uri)
  request["X-aws-ec2-metadata-token"] = token
  res = Net::HTTP.new("169.254.169.254").request(request)
  metadata = res.body if res.code == '200'
  metadata
end

def rm_libmpich
  # Uninstall libmpich-dev, which configures an /usr/lib/libmpi.so symlink
  # The symlink causes an mpicc issue with -L/usr/lib linker flag in efa installer v1.12.x + ubuntu1804
  # Compile slurm with the package to enable mpich binding for slurm, and remove after
  return unless node['platform_version'] == '18.04'

  package "libmpich-dev" do
    action :remove
  end
end
