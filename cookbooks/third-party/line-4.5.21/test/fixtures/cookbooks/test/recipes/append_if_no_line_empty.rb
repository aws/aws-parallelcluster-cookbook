#
# Append to empty file
#

user 'test_user'

file '/tmp/emptyfile'

append_if_no_line 'should add to empty file' do
  path '/tmp/emptyfile'
  line 'added line'
end

append_if_no_line 'missing_file' do
  path '/tmp/missing_create'
  line 'added line'
end

append_if_no_line 'missing_file with owner, group, mode' do
  path '/tmp/missing_create_owner'
  line 'Owned by test_user'
  owner 'test_user'
  group 'test_user'
  mode '0600'
end

append_if_no_line 'missing_file fail' do
  path '/tmp/missing_fail'
  line 'added line'
  ignore_missing false
  ignore_failure true
end
