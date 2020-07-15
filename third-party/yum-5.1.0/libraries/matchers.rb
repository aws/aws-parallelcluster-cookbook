if defined?(ChefSpec)
  def create_yum_globalconfig(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:yum_globalconfig, :create, resource_name)
  end

  def delete_yum_globalconfig(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:yum_globalconfig, :delete, resource_name)
  end
end
