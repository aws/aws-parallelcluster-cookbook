# Created shared mount point
directory node['cfncluster']['cfn_shared_dir'] do
  mode '1777'
  owner 'root'
  group 'root'
end

node.set['cfncluster']['cfn_master'] = node['cfncluster']['cfn_master'].split('.')[0]

nfs_master = "#{node['cfncluster']['cfn_master']}"

# Mount shared volume over NFS
mount node['cfncluster']['cfn_shared_dir'] do
  device "#{nfs_master}:#{node['cfncluster']['cfn_shared_dir']}"
  fstype 'nfs'
  options 'hard,intr,noatime,vers=3,_netdev'
  action [:mount, :enable]
end

# Mount /home over NFS
mount '/home' do
  device "#{nfs_master}:/home"
  fstype 'nfs'
  options 'hard,intr,noatime,vers=3,_netdev'
  action [:mount, :enable]
end

# Configure Ganglia
template '/etc/ganglia/gmond.conf' do
  source 'gmond.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

service "gmond" do
  supports :restart => true
  action [ :enable, :start ]
end

# Setup cluster user
user "#{node['cfncluster']['cfn_cluster_user']}" do
  supports :manage_home => false
  comment 'cfncluster user'
  home "/home/#{node['cfncluster']['cfn_cluster_user']}"
  shell '/bin/bash'
end

# Install nodewatcher.cfg
template '/etc/nodewatcher.cfg' do
  source 'nodewatcher.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
