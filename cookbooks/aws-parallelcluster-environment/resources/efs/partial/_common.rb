unified_mode true

default_action :install_utils

property :efs_utils_version, String, default: '2.3.1'
property :efs_utils_checksum, String, default: 'ced12f82e76f9740476b63f30c49bd76cc00b6375e12a9f5f7ba852635c49e15'

def already_installed?(package_name, expected_version)
  Gem::Version.new(get_package_version(package_name)) >= Gem::Version.new(expected_version)
end

def get_package_version(package_name)
  cmd = get_package_version_command(package_name)
  version = shell_out(cmd).stdout.strip
  if version.empty?
    Chef::Log.info("#{package_name} not found when trying to get the version.")
  end
  version
end

action :increase_poll_interval do
  # An interval too short could affect HPC workload performance
  replace_or_add "increase EFS-utils watchdog poll interval" do
    path "/etc/amazon/efs/efs-utils.conf"
    pattern "poll_interval_sec = 1$"
    line "poll_interval_sec = 10"
    replace_only true
  end
end
