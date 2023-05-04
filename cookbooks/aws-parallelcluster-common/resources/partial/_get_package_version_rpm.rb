def get_package_version_command(package_name)
  "rpm -qi #{package_name} | grep Version | awk '{print $3}'"
end
