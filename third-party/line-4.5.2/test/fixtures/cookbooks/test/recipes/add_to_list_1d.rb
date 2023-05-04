#
# Test for lists with 1 delimitor ,
#

template '/tmp/1d' do
  source 'samplefile3.erb'
  action :create_if_missing
end

add_to_list 'Add to an empty list, seperator' do
  path '/tmp/1d'
  pattern /empty_list=/
  delim [' ']
  entry 'newentry'
end

add_to_list 'Add a duplicate entry to a list, seperator' do
  path '/tmp/1d'
  pattern /People to call:/
  delim [', ']
  entry 'Bobby'
end

add_to_list 'Add a new entry to a list, seperator' do
  path '/tmp/1d'
  pattern /People to call:/
  delim [', ']
  entry 'Harry'
end
