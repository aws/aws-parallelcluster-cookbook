#
# Test for lists with 1 delimitor and a terminal " , "
#

template '/tmp/1d_term' do
  source 'samplefile3.erb'
  action :create_if_missing
end

add_to_list 'Add to an empty list, seperator, terminal' do
  path '/tmp/1d_term'
  pattern /DEFAULT_APPEND_EMPTY="/
  delim [' ']
  ends_with '"'
  entry 'first'
end

add_to_list 'Add an existing item a list, seperator, terminal' do
  path '/tmp/1d_term'
  pattern /DEFAULT_APPEND="/
  delim [' ']
  ends_with '"'
  entry 'showopts'
end

add_to_list 'Add a new item a list, seperator, terminal' do
  path '/tmp/1d_term'
  pattern /DEFAULT_APPEND="/
  delim [' ']
  ends_with '"'
  entry 'newopt'
end
