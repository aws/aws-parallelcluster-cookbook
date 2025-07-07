#
# Add a line that exactly matches the specified pattern.
#

template '/tmp/add_a_line_matching_pattern' do
  source 'text_file.erb'
  action :create_if_missing
end

replace_or_add 'add_a_line_matching_pattern' do
  path '/tmp/add_a_line_matching_pattern'
  pattern 'Add another line'
  line 'Add another line'
end
