#
# Delete lines using a regex pattern
#

template '/tmp/regexp_pattern_1' do
  source 'samplefile.erb'
  action :create_if_missing
end

template '/tmp/regexp_pattern_2' do
  source 'samplefile.erb'
  action :create_if_missing
end

delete_lines 'Delete Regex Pattern 1' do
  path '/tmp/regexp_pattern_1'
  pattern /^HELLO.*/
end

delete_lines 'Delete Regex Pattern 1' do
  path '/tmp/regexp_pattern_2'
  pattern /^#.*/
end
