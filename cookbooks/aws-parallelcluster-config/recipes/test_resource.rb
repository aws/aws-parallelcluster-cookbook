# This is a helper recipe executing an action of the resource
# which type was set as `resource` attribute during the test execution.
# Expected syntax for the resource attribute is resource-name:optional-action

resource_item = node['resource'].split(/:/)
if resource_item[1].nil?
  # default action
  declare_resource(resource_item[0], 'test')
else
  declare_resource(resource_item[0], 'test') do
    action resource_item[1]
  end
end
