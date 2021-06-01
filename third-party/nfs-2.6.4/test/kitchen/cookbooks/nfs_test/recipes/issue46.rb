%w(share1 share2 share3).each do |share|
  directory "/tmp/#{share}"
end

%w(user1 user2 user3).each do |u|
  group u if node['platform_family'] == 'suse'
  user u
end

nfs_export '/tmp/share1' do
  network '127.0.0.1'
  anonuser 'user1'
  anongroup 'user1'
end

nfs_export '/tmp/share2' do
  network '127.0.0.1'
  anonuser 'user2'
  anongroup 'user2'
end

nfs_export '/tmp/share3' do
  network '127.0.0.1'
  anonuser 'user3'
  anongroup 'user3'
end
