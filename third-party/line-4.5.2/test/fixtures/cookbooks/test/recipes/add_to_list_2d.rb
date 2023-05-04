#
# Test for lists with 2 delimitors ||, ||
#

template '/tmp/2d' do
  source 'samplefile3.erb'
  action :create_if_missing
end

add_to_list 'Add an item to an empty list, seperator and item delimiters' do
  path '/tmp/2d'
  pattern /wo2d_empty=/
  delim [',', '"']
  entry 'single'
end

add_to_list 'Add an existing entry to a list, seperator and item delimiters' do
  path '/tmp/2d'
  pattern /wo2d_list/
  delim [',', '"']
  entry 'first2'
end

add_to_list 'Add a new entry to a list, seperator and item delimiters' do
  path '/tmp/2d'
  pattern /wo2d_list/
  delim [',', '"']
  entry 'third2'
end
