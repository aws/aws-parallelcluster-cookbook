#
# Add to list in an empty file
#

file '/tmp/emptyfile'

add_to_list 'Empty files that are not changed should stay empty' do
  path '/tmp/emptyfile'
  pattern  /line=/
  delim [' ']
  entry 'should_not_be_added'
end

add_to_list 'missing_nothing' do
  path '/tmp/missingfile'
  pattern /empty_delimited_list=\(/
  delim [', ', '"']
  ends_with ')'
  entry 'newentry'
end

add_to_list 'missing_file fail' do
  path '/tmp/missingfile'
  pattern /empty_delimited_list=\(/
  delim [', ', '"']
  ends_with ')'
  entry 'newentry'
  ignore_missing false
  ignore_failure true
end
