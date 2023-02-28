require 'chefspec'
require 'chefspec/berkshelf'

module ChefSpec
  class Runner
    # Allows to converge a dynamic code block
    # For instance, it can be used to invoke actions on resources
    def converge_dsl(*recipes, &block)
      cookbook_name = 'any'
      recipe_name = 'any'
      converge(*recipes) do
        recipe = Chef::Recipe.new(cookbook_name, recipe_name, @run_context)
        recipe.instance_eval(&block)
      end
    end
  end
end

def for_all_oses(&block)
  [
    %w(amazon 2),
    # The only Centos7 version supported by ChefSpec
    # See the complete list here: https://github.com/chefspec/fauxhai/blob/main/PLATFORMS.md
    %w(centos 7.8.2003),
    %w(ubuntu 18.04),
    %w(ubuntu 20.04),
    %w(redhat 8),
  ].each do |platform, version|
    context "on #{platform}#{version}" do
      block.call(platform, version)
    end
  end
end
