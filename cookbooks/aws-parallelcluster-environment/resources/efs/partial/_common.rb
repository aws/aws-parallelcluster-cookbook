unified_mode true

default_action :install_utils

property :efs_utils_version, String, default: '2.1.0'
property :efs_utils_checksum, String, default: '2996bdd5387131d302310812fa1e07e1be00f80814a580f5dfeb27d68519fd24'

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
