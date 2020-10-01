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
  match = fs_check.stdout.match(/\sPTTYPE=\"(.*?)\"/)
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
  match = fs_check.stdout.match(/\sTYPE=\"(.*?)\"/)
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
  match = fs_check.stdout.match(/\sUUID=\"(.*?)\"/)
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
  partition = "/dev/" + fs_check.stdout.strip
  Chef::Log.info("1st partition for device: #{device} is: #{partition}")
  partition
end

#
# Get vpc-ipv4-cidr-blocks
#
def get_vpc_ipv4_cidr_blocks(eth0_mac)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{eth0_mac.downcase}/vpc-ipv4-cidr-blocks")
  res = Net::HTTP.get_response(uri)
  vpc_ipv4_cidr_blocks = res.body if res.code == '200'
  # Parse into array
  vpc_ipv4_cidr_blocks = vpc_ipv4_cidr_blocks.split("\n")
  vpc_ipv4_cidr_blocks
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
  has_gpu = `lspci | grep -i -o 'NVIDIA'`
  is_graphic_instance = !has_gpu.strip.empty?

  is_graphic_instance
end

#
# Check if the AMI is bootstrapped
#
def ami_bootstrapped?
  version = ''
  bootstrapped_file = '/opt/parallelcluster/.bootstrapped'
  current_version = 'aws-parallelcluster-cookbook-' + node['cfncluster']['cfncluster-cookbook-version']

  if ::File.exist?(bootstrapped_file)
    version = IO.read(bootstrapped_file).chomp
    Chef::Log.info("Detected bootstrap file #{version}")
    if version != current_version
      raise "This AMI was created with " + version + ", but is trying to be used with " + current_version + ". " \
            "Please either use an AMI created with " + current_version + " or change your ParallelCluster to " + version
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
    current_os = 'ubuntu' + node['platform_version'].tr('.', '')
    raise_os_not_match(current_os, node['cfncluster']['cfn_base_os']) if node['cfncluster']['cfn_base_os'] != current_os
  when 'amazon'
    if node['platform_version'].to_i > 2010 && node['cfncluster']['cfn_base_os'] != 'alinux'
      raise_os_not_match("alinux", node['cfncluster']['cfn_base_os'])
    elsif node['platform_version'].to_i == 2 && node['cfncluster']['cfn_base_os'] != 'alinux2'
      raise_os_not_match("alinux2", node['cfncluster']['cfn_base_os'])
    end
  when 'centos'
    current_os = 'centos' + node['platform_version'].to_i.to_s
    raise_os_not_match(current_os, node['cfncluster']['cfn_base_os']) if node['cfncluster']['cfn_base_os'] != current_os
  end
end

#
# Raise error if OS types do not match
#
def raise_os_not_match(current_os, specified_os)
  raise "The custom AMI you have provided uses the " + current_os + " OS." \
        "However, the base_os specified in your config file is " + specified_os + ". " \
        "Please either use an AMI with the " + specified_os + " OS or update the base_os " \
        "setting in your configuration file to " + current_os + "."
end

#
# Retrieve master ip and dns from file (HIT only)
#
def hit_master_info
  master_private_ip_file = "#{node['cfncluster']['slurm_plugin_dir']}/master_private_ip"
  master_private_dns_file = "#{node['cfncluster']['slurm_plugin_dir']}/master_private_dns"

  [IO.read(master_private_ip_file).chomp, IO.read(master_private_dns_file).chomp]
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

  slurm_nodename, master_private_ip, master_private_dns = output.split(/\s+/)

  Chef::Log.info("Retrieved Slurm nodename is: #{slurm_nodename}")
  Chef::Log.info("Retrieved master private ip: #{master_private_ip}")
  Chef::Log.info("Retrieved master private dns: #{master_private_dns}")

  [slurm_nodename, master_private_ip, master_private_dns]
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
#
def restart_network_service
  network_service_name = value_for_platform(
    ['centos'] => {
      '>=8.0' => 'NetworkManager'
    },
    %w[ubuntu debian] => {
      '16.04' => 'networking',
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
#
def reload_network_config
  if node['platform'] == 'ubuntu' && node['platform_version'].to_i == 18
    Mixlib::ShellOut.new("netplan apply").run_command
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
  [node['platform'] == 'ubuntu' && node['platform_version'].to_i == 18,
   node['platform'] == 'amazon' && node['platform_version'].to_i == 2,
   node['platform'] == 'centos' && node['platform_version'].to_i == 8].any?
end

def aws_domain
  # Set the aws domain name
  aws_domain = "amazonaws.com"
  aws_domain = "#{aws_domain}.cn" if node['cfncluster']['cfn_region'].start_with?("cn-")
  aws_domain
end

#
# Retrieve RHEL kernel minor version from running kernel
# The minor version is retrieved from the patch version of the running kernel
# following the mapping reported here https://access.redhat.com/articles/3078#RHEL7
# Method works for minor version >=7
#
def find_rhel7_kernel_minor_version
  kernel_minor_version = '7'

  if node['platform'] == 'centos'
    # kernel release is in the form 3.10.0-1127.8.2.el7.x86_64
    kernel_patch_version = node['kernel']['release'].match(/^\d+\.\d+\.\d+-(\d+)\..*$/)
    raise "Unable to retrieve the kernel minor version from #{node['kernel']['release']}." unless kernel_patch_version

    kernel_minor_version = '8' if kernel_patch_version[1] >= '1127'
  end

  kernel_minor_version
end

# Return chrony service reload command
# Chrony doesn't support reload but only force-reload command
def chrony_reload_command
  if node['init_package'] == 'init'
    chrony_reload_command = "service #{node['cfncluster']['chrony']['service']} force-reload"
  elsif node['init_package'] == 'systemd'
    chrony_reload_command = "systemctl force-reload #{node['cfncluster']['chrony']['service']}"
  else
    raise "Init package #{node['init_package']} not supported."

  end

  chrony_reload_command
end

# Add an external package repository to the OS's package manager
def add_package_repository(repo_name, baseurl, gpgkey, distribution)
  if node['platform_family'] == 'rhel' || node['platform_family'] == 'amazon'
    yum_repository repo_name do
      baseurl baseurl
      gpgkey gpgkey
      retries 3
      retry_delay 5
    end
  elsif node['platform_family'] == 'debian'
    apt_repository repo_name do
      uri          baseurl
      key          gpgkey
      distribution distribution
      retries 3
      retry_delay 5
    end
    apt_update
  else
    raise "platform not supported: #{node['platform_family']}"
  end
end

# Remove an external package repository from the OS's package manager
def remove_package_repository(repo_name)
  if node['platform_family'] == 'rhel' || node['platform_family'] == 'amazon'
    yum_repository repo_name do
      action :remove
    end
  elsif node['platform_family'] == 'debian'
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
  if node['cfncluster']['cfn_node_type'] == "ComputeFleet"
    enabling_value = "compute"
  else
    enabling_value = "master"
  end
  (config_value == enabling_value || config_value == "cluster") && graphic_instance?
end
