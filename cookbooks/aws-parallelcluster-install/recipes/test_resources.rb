# This is a helper recipe executing the default action of the resource
# which type was set as `resource` attribute during the test execution.
# This is equivalent to:
# resource_type 'test'
# or
# resource_type 'test' do
#   action :default_action
# end

node['resources'].each do |resource|
  declare_resource(resource.to_sym, 'test')
end
