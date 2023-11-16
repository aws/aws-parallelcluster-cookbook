#
# Delete lines using a string regex pattern
#

template '/tmp/string_pattern_1' do
  source 'samplefile.erb'
  action :create_if_missing
end

template '/tmp/string_pattern_2' do
  source 'samplefile.erb'
  action :create_if_missing
end

delete_lines 'Delete String Pattern 1' do
  path '/tmp/string_pattern_1'
  pattern '^HELLO.*'
  backup true
end

delete_lines 'Delete String Pattern 2' do
  path '/tmp/string_pattern_2'
  pattern '^#.*'
end
