action :validate do
  Chef::Log.info("Checking for MySql implementation on #{node['platform']}:#{node['kernel']['machine']}")
  repository_packages.each do |pkg|
    validate_package_version(pkg, expected_version)
  end
end
