#
# Delete from list with 3 deliminators [], []
#

template '/tmp/3d' do
  source 'samplefile3.erb'
  action :create_if_missing
end

delete_from_list 'Delete entry' do
  path '/tmp/3d'
  pattern /wo3d_list=/
  delim [',', '[', ']']
  entry 'first3'
end

delete_from_list 'Delete entry terminal' do
  path '/tmp/3d'
  pattern /multi = /
  delim [', ', '[', ']']
  entry '323'
end

delete_from_list 'Delete not exists' do
  path '/tmp/3d'
  pattern /multi = /
  delim [', ', '[', ']']
  entry '425'
end
