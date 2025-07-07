#
# Verify the results of using the comment filter
#

template '/tmp/comment' do
  source 'samplefile.erb'
  action :create_if_missing
end

filter_lines 'Change matching lines to comments' do
  path '/tmp/comment'
  sensitive false
  filters comment: [/I/]
end
