action :cloudwatch_install_package do
  dpkg_package package_path do
    source package_path
  end
end

action_class do
  def platform_url_component
    node['platform']
  end

  def package_extension
    'deb'
  end
end
