action :cloudwatch_install_package do
  package package_path
end

action_class do
  def package_extension
    'rpm'
  end
end
