#
# Append to simple file
#

file '/tmp/single_line_file' do
  content 'single line file'
  action :create_if_missing
end

append_if_no_line 'should go on its own line' do
  path '/tmp/single_line_file'
  line 'SHOULD GO ON ITS OWN LINE'
end

append_if_no_line 'should not edit the file' do
  path '/tmp/single_line_file'
  line 'single line file'
end
