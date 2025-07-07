#
# Test for lists with 2 delimitors and a terminal (||, ||)
#

template '/tmp/2d_term' do
  source 'samplefile3.erb'
  action :create_if_missing
end

add_to_list 'Add a new entry to empty list, seperator, item delimiters, terminal' do
  path '/tmp/2d_term'
  pattern /empty_delimited_list=\(/
  delim [', ', '|']
  ends_with ')'
  entry 'empty'
end

add_to_list 'Add an existing entry, seperator, item delimiters, terminal' do
  path '/tmp/2d_term'
  pattern /last_delimited_list= \(/
  delim [', ', '|']
  ends_with ')'
  entry 'single'
end

add_to_list 'Add a new entry, seperator, item delimiters, terminal' do
  path '/tmp/2d_term'
  pattern /last_delimited_list= \(/
  delim [', ', '|']
  ends_with ')'
  entry 'double'
end
