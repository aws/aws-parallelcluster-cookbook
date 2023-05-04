#
# Test for lists with 3 delimitors [], []
#

template '/tmp/3d' do
  source 'samplefile3.erb'
  action :create_if_missing
end

add_to_list 'Add first entry to a list, seperator, item delimiters' do
  path '/tmp/3d'
  pattern /wo3d_empty=/
  delim [',', '[', ']']
  entry 'single'
end

add_to_list 'Add an existing entry, seperator, item delimiters' do
  path '/tmp/3d'
  pattern /wo3d_list/
  delim [',', '[', ']']
  entry 'first3'
end

add_to_list 'Add a new entry, seperator, item delimiters' do
  path '/tmp/3d'
  pattern /wo3d_list/
  delim [',', '[', ']']
  entry 'third3'
end
