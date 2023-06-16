#
# Verify the results of using the delete_between filter
#

template '/tmp/delete_between' do
  source 'samplefile3.erb'
  action :create_if_missing
end

filter_lines 'Delete lines between matches' do
  path '/tmp/delete_between'
  sensitive false
  filters delete_between: [/^empty_list/, /^list/, /kernel/]
end
