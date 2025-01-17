#
# Delete from list with 1 deliminator ,
#

template '/tmp/1d' do
  source 'samplefile3.erb'
  action :create_if_missing
end

delete_from_list 'Delete space delim' do
  path '/tmp/1d'
  pattern /^\s*kernel /
  delim [' ']
  entry 'rhgb'
end

delete_from_list 'Delete comma space' do
  path '/tmp/1d'
  pattern /People to call:/
  delim [', ']
  entry 'Joe'
end

delete_from_list 'Delete space comma' do
  path '/tmp/1d'
  pattern /^list/
  delim [' ,']
  entry 'third'
end

delete_from_list 'Delete not exists' do
  path '/tmp/1d'
  pattern /People to call:/
  delim [', ']
  entry 'Harry'
end
