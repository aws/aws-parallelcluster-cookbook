def already_installed?(package_name, expected_version)
  Gem::Version.new(get_package_version(package_name)) >= Gem::Version.new(expected_version)
end
