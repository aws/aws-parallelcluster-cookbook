#
# Delete from a list on an empty file
#

file '/tmp/emptyfile'

delete_from_list 'Empty file' do
  path '/tmp/emptyfile'
  pattern /list=/
  delim [' ']
  entry 'not_there'
end

delete_from_list 'missing_file' do
  path '/tmp/missingfile'
  pattern /multi = /
  delim [', ', '[', ']']
  entry '425'
end

delete_from_list 'missing_file fail' do
  path '/tmp/missingfile'
  pattern /multi = /
  delim [', ', '[', ']']
  entry '425'
  ignore_missing false
  ignore_failure true
end
