#
# Delete lines on an empty file
#

file '/tmp/emptyfile'

delete_lines 'Empty file should not change' do
  path '/tmp/emptyfile'
  pattern /.*/
end

delete_lines 'missing_file fail' do
  path '/tmp/missingfile'
  pattern '.*'
  ignore_missing false
  ignore_failure true
end

delete_lines 'missing_file' do
  path '/tmp/missingfile'
  pattern '.*'
end
