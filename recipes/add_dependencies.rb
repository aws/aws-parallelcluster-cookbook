# This is a helper recipe to automatically add dependencies, including recipes and resources
# This is useful if you need to test a resource with recipe/resources dependencies in the kitchen.resources/recipes.yml.

# To use it add recipe[aws-parallelcluster::add_dependencies] as first item in the run_list
# then define a dependencies attribute, listing them with recipe: or resource: prefix. Example:

#- name: resource_with_deps
#  run_list:
#    - recipe[aws-parallelcluster::add_dependencies]
#    - recipe[aws-parallelcluster-install::test_resource_or_recipe_to_test]
#  verifier:
#    controls:
#      - resource_control_name
#  attributes:
#    resource: resource_name
#    dependencies:
#      - recipe:aws-parallelcluster::test_dummy
#      - recipe:aws-parallelcluster-install::directories
#      - resource:ec2_udev_rules

if defined?(node['dependencies'])
  node['dependencies'].each do |dep|
    if dep.start_with?('recipe:')
      include_recipe dep.gsub('recipe:', '')
    else
      declare_resource(dep.gsub('resource:', ''), 'test')
    end
  end
end
