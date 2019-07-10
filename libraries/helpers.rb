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
# Check if block device has a fileystem
#
def get_fs_type(device)
  fs_check = Mixlib::ShellOut.new("blkid -c /dev/null #{device}")
  fs_check.run_command
  match = fs_check.stdout.match(/TYPE=\"(.*)\"/)
  match = '' if match.nil?

  match[1]
end

#
# Get vpc-ipv4-cidr-block
#
def get_vpc_ipv4_cidr_block(eth0_mac)
  uri = URI("http://169.254.169.254/latest/meta-data/network/interfaces/macs/#{eth0_mac.downcase}/vpc-ipv4-cidr-block")
  res = Net::HTTP.get_response(uri)
  vpc_ipv4_cidr_block = res.body if res.code == '200'

  vpc_ipv4_cidr_block
end

def get_instance_type()
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
