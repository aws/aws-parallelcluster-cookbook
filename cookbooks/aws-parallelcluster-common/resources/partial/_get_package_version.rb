def get_package_version(package_name)
  cmd = get_package_version_command(package_name)
  package_version_cmd = Mixlib::ShellOut.new(cmd)
  version = package_version_cmd.run_command.stdout.strip
  if version.empty?
    Chef::Log.info("#{package_name} not found when trying to get the version.")
  end
  version
end
