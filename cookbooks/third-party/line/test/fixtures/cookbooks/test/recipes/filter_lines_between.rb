#
# Verify the results of using the between filter
#

template '/tmp/between' do
  source 'samplefile3.erb'
  action :create_if_missing
end

filter_lines 'Change lines between matches' do
  path '/tmp/between'
  sensitive false
  filters between: [/^empty/, /last_list/, ['add line']]
end
