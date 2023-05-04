#
# Test for lists with 3 delimitors and a terminal ([], [])
#

template '/tmp/3d_term' do
  source 'samplefile3.erb'
  action :create_if_missing
end

add_to_list 'Add a new entry to empty list, seperator, item delimiters, terminal' do
  path '/tmp/3d_term'
  pattern /empty_3delim=\(/
  delim [', ', '[', ']']
  ends_with ')'
  entry '3_with_end'
end

add_to_list 'Add an existing entry, seperator, item delimiters, terminal' do
  path '/tmp/3d_term'
  pattern /multi = \(/
  delim [', ', '[', ']']
  ends_with ')'
  entry '323'
end

add_to_list 'Add a new entry, seperator, item delimiters, terminal' do
  path '/tmp/3d_term'
  pattern /multi = \(/
  delim [', ', '[', ']']
  ends_with ')'
  entry '789'
end
