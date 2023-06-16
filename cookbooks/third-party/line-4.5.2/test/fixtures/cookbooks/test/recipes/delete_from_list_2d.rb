#
# Delete from list with 2 deliminators ||, ||
#

template '/tmp/2d' do
  source 'samplefile3.erb'
  action :create_if_missing
end

delete_from_list 'Delete one' do
  path '/tmp/2d'
  pattern /my @net1918 =/
  delim [', ', '"']
  entry '10.0.0.0/8'
end

delete_from_list 'Delete only' do
  path '/tmp/2d'
  pattern /last_delimited_list= \(/
  delim [', ', '|']
  entry 'single'
end

delete_from_list 'Delete not exists' do
  path '/tmp/2d'
  pattern /my @net1918 =/
  delim [', ', '"']
  entry '10.0.0.1/8'
end
