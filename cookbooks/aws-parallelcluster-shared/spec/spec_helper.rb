require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |c|
  c.before(:each) do
    allow(File).to receive(:exist?).and_call_original
    allow(Dir).to receive(:exist?).and_call_original
    allow_any_instance_of(Object).to receive(:aws_domain).and_return("test_aws_domain")
    allow_any_instance_of(Object).to receive(:aws_region).and_return("test_region")
  end
  # This will be used by default when platform doesn't matter
  # When it matters, platform value must be overridden for a specific test
  c.platform = 'ubuntu'
end

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

def for_oses(os_list)
  os_list.each do |platform, version|
    yield(platform, version)
  end
end

def for_all_oses
  [
    %w(amazon 2),
    # The only Centos7 version supported by ChefSpec
    # See the complete list here: https://github.com/chefspec/fauxhai/blob/main/PLATFORMS.md
    %w(centos 7.8.2003),
    %w(ubuntu 20.04),
    %w(ubuntu 22.04),
    %w(redhat 8),
    %w(rocky 8),
    %w(redhat 9),
    %w(rocky 9),
  ].each do |platform, version|
    yield(platform, version)
  end
end

def runner(platform:, version:, step_into: [])
  ChefSpec::SoloRunner.new(platform: platform, version: version, step_into: step_into) do |node|
    yield node if block_given?
  end
end

def mock_exist_call_original
  # This is required before mocking existence of specific files
  allow(File).to receive(:exist?).and_call_original
end

def block_stepping_into_recipe
  allow_any_instance_of(Chef::RunContext).to receive(:include_recipe) do |_context, recipe|
    Chef::Log.debug "Attempt to include #{recipe} blocked"
  end
end

def mock_file_exists(file, exists)
  allow(::File).to receive(:exist?).with(file).and_return(exists)
end

def expect_to_include_recipe_from_resource(recipe, cookbook = 'any')
  expect_any_instance_of(Chef::RunContext).to receive(:include_recipe).with(recipe, { current_cookbook: cookbook })
end

at_exit { ChefSpec::Coverage.report! }
