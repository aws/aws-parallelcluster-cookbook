return if virtualized?

directory '/fake_headnode_home'
directory '/fake_headnode_shared'

bash 'rsync /home' do
  code "rsync -avz /home/* /fake_headnode_home/"
end

nfs_export "/fake_headnode_home" do
  network '127.0.0.1/32'
  writeable true
  options ['no_root_squash']
end

nfs_export "/fake_headnode_shared" do
  network '127.0.0.1/32'
  writeable true
  options ['no_root_squash']
end

bash 'Disable selinux if exist' do
  code "setenforce 0 || echo 'KO'"
end
