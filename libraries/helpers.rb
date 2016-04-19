require 'chef/mixin/shell_out'
require 'net/http'
require 'timeout'

#
# Wait 60 seconds for the block device to be ready
#
def wait_for_block_dev(path)
  Timeout.timeout(60) do
    sleep(1) until ::File.blockdev?(path)
    Chef::Log.debug("device ${path} not ready - sleeping 1s")
  end
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
