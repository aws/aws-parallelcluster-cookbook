def get_package_version_command(package_name)
  # TODO: These commands do not fit all packages versions. e.g. dpkg-query --showformat='${Version}' --show stunnel4 | awk -F- '{print $1}'
  "dpkg-query --showformat='${Version}' --show #{package_name} | awk -F- '{print $1}'"
end
