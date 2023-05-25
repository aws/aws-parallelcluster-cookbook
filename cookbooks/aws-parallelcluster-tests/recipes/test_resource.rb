# This is a helper recipe executing an action of the resource
# Usage:
#   - name: <suite_name>
#     run_list:
#       - recipe[aws-parallelcluster-tests::test_resource]
#     attributes:
#       resource: <resource_name>[:<resource_action>]
#       [resource_properties:
#         <resource_property_1_name>: <resource_property_1_value>
#         <resource_property_2_name>: <resource_property_2_value>]
#
# Examples
#
#   - name: resource_with_defaults
#     run_list:
#       - recipe[aws-parallelcluster-tests::test_resource]
#     attributes:
#       resource: resource_name
#
#   - name: resource_with_action
#     run_list:
#       - recipe[aws-parallelcluster-tests::test_resource]
#     attributes:
#       resource: resource_name:action
#
#   - name: resource_with_properties
#     run_list:
#       - recipe[aws-parallelcluster-tests::test_resource]
#     attributes:
#       resource: resource_name
#       resource_properties:
#         property1: x
#         property2: y
#

resource_item = node['resource'].split(/:/)
resource_properties = node['resource_properties'] || {}

declare_resource(resource_item[0], 'test') do
  resource_properties.each_key do |key|
    send("#{key}=", resource_properties[key])
  end
  action resource_item[1]
end
