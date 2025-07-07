#
# Change the last line of a file
#

template '/tmp/change_line_eof' do
  source 'text_file.erb'
  action :create_if_missing
end

replace_or_add 'change_line_eof' do
  path '/tmp/change_line_eof'
  pattern 'Last line'
  line 'Last line changed'
end
