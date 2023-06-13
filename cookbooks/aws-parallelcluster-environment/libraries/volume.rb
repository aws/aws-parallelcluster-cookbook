#
# Wait 60 seconds for the block device to be ready
#
def wait_for_block_dev(path)
  Timeout.timeout(600) do
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
  shell_out("echo 1 > /sys/bus/pci/rescan")
end

#
# Ensure directory has the right format (i.e. starts with `/`).
#
def format_directory(dir)
  format_dir = dir.strip
  format_dir = "/#{format_dir}" unless format_dir.start_with?('/')
  format_dir
end
