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

def get_instance_type
  uri = URI("http://169.254.169.254/latest/meta-data/instance-type")
  res = Net::HTTP.get_response(uri)
  master_instance_type = res.body if res.code == '200'

  master_instance_type
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

  if ::File.exist?(bootstrapped_file)
    version = IO.read(bootstrapped_file).chomp
    Chef::Log.info("Detected bootstrap file #{version}")
  end

  'aws-parallelcluster-' + node['cfncluster']['cfncluster-version'] == version && node['cfncluster']['skip_install_recipes'] == 'yes'
end

def master_address(region, stack_name)
  require 'chef/mixin/shell_out'

  output = shell_out!("aws ec2 describe-instances --filters '[{\"Name\":\"tag:Application\", \"Values\": " \
                      "[\"#{stack_name}\"]},{\"Name\":\"tag:aws-parallelcluster-node-type\", \"Values\": [\"Master\"]},{\"Name\": " \
                      "\"instance-state-name\", \"Values\": [\"running\"]}]' --region #{region} --query " \
                      "\"Reservations[0].Instances[0].[PrivateIpAddress,PrivateDnsName]\" --output text").stdout.strip

  raise "Failed when retrieving Master server address: unable to describe EC2 instance" if output == "None"

  master_private_ip, master_private_dns = output.split(/\s+/)
  Chef::Log.info("Retrieved master private ip: #{master_private_ip}")
  Chef::Log.info("Retrieved master private dns: #{master_private_dns}")

  [master_private_ip, master_private_dns]
end

#
# Check if this is an ARM instance
#
def arm_instance?
  node['kernel']['machine'] == 'aarch64'
end

#
# Check if this is an OS on which EFA is supported
#
def platform_supports_efa?
  [node['platform'] == 'centos' && node['platform_version'].to_i >= 7,
   node['platform'] == 'amazon',
   node['platform'] == 'ubuntu'].any?
end

#
# Check if the platform supports intel MPI
#
def platform_supports_impi?
  [node['platform'] == 'centos' && node['platform_version'].to_i >= 7,
   node['platform'] == 'amazon',
   node['platform'] == 'ubuntu'].any?
end

#
# Check if this platform supports intel's HPC platform
#
def platform_supports_intel_hpc_platform?
  node['platform'] == 'centos' && node['platform_version'].to_i >= 7
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
  [arm_instance? && platform_supports_lustre_on_arm?,
   !arm_instance? && platform_supports_lustre_on_x86_64?].any?
end

#
# Check if Lustre is supported for x86_64 instances on this OS
#
def platform_supports_lustre_on_x86_64?
  [node['platform'] == 'centos' && node['platform_version'].to_i >= 7,
   node['platform'] == 'amazon',
   node['platform'] == 'ubuntu'].any?
end

#
# Check if Lustre is supported for ARM instances on this OS
#
def platform_supports_lustre_on_arm?
  [node['platform'] == 'ubuntu' && node['platform_version'].to_i == 18,
   node['platform'] == 'amazon' && node['platform_version'].to_i == 2].any?
end

def aws_domain
  # Set the aws domain name
  aws_domain = "amazonaws.com"
  aws_domain = "#{aws_domain}.cn" if node['cfncluster']['cfn_region'].start_with?("cn-")
  aws_domain
end

#
# Chedk if PMIx is supported on this OS. It's not built on CentOS 6
# because doing so would require installing newer versions of automake,
# autoconf, libtool, and libevent. This was deemed more effort than it
# was worth for an OS that will reach EOL soon.
#
def platform_supports_pmix?
  node['platform'] != 'centos' || node['platform_version'].to_i > 6
end
