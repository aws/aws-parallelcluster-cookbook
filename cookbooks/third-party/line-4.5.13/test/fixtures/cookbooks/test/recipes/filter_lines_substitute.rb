#
# Verify the results of using the substitute filter
#

template '/tmp/substitute' do
  source 'samplefile3.erb'
  action :create_if_missing
end

filter_lines 'Substitute string for matching pattern' do
  path '/tmp/substitute'
  filters substitute: [/last/, /last_list/, 'start_list']
end
