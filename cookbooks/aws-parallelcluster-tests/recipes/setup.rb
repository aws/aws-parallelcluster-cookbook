# This is a helper recipe to automatically add dependencies, including recipes and resources
# This is useful if you need to test a resource with recipe/resources dependencies in the kitchen.resources/recipes.yml.

# To use it add recipe[aws-parallelcluster-tests::setup] as first item in the run_list
# then define a dependencies attribute, listing them with recipe: or resource: prefix.
# For resources is also possible to specify the action. Example:

#- name: resource_with_deps
#  run_list:
#    - recipe[aws-parallelcluster-tests::setup]
#    - recipe[aws-parallelcluster-platform::test_resource_or_recipe_to_test]
#  verifier:
#    controls:
#      - resource_control_name
#  attributes:
#    resource: resource_name
#    dependencies:
#      - recipe:aws-parallelcluster-platform::directories
#      - resource:ec2_udev_rules
#      - resource:package_repos:update

node_attributes 'dump node attributes'
include_recipe '::docker_mock'

if defined?(node['dependencies']) && node['dependencies']
  node['dependencies'].each do |dep|
    if dep.start_with?('recipe:')
      include_recipe dep.gsub('recipe:', '')
    else
      descriptor = dep.gsub('resource:', '')
      test_resource 'resource' do
        descriptor descriptor
      end
    end
  end
end
