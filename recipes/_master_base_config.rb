# Run configure-pat and add to rc.local
execute "run_configure-pat" do
  command '/usr/local/sbin/configure-pat.sh'
  # no not_if as script is idempotent
end

# Add configure-pat to /etc/rc.local
execute "add_configure-pat" do
  command 'echo -e "\n# Enable PAT\n/usr/local/sbin/configure-pat.sh\n\n" >> /etc/rc.local'
  not_if 'grep -qx /usr/local/sbin/configure-pat.sh /etc/rc.local'
end

dev_path = "/dev/disk/by-ebs-volumeid/#{node['cfncluster']['cfn_volume']}"

# Attach EBS volume
execute "attach_volume" do
  command "/usr/local/sbin/attachVolume.py #{node['cfncluster']['cfn_volume']}"
  creates dev_path
end

# wait for the drive to attach, before making a filesystem
ruby_block "sleeping_for_volume" do
  block do
    wait_for_block_dev(dev_path)
  end
  subscribes :run, "execute[attach_volume]", :immediately
end

# Setup disk, will be formatted xfs if empty
ruby_block "setup_disk" do
  block do
    fs_type = setup_disk(dev_path)
    node.set['cfncluster']['cfn_volume_fs_type'] = fs_type
  end
  subscribes :run, "ruby_block[sleeping_for_volume]", :immediately
end

# Create the shared directory
directory "#{node['cfncluster']['cfn_shared_dir']}" do
  owner 'root'
  group 'root'
  mode '0777'
  recursive true
  action :create
end

# Add volume to /etc/fstab
mount "#{node['cfncluster']['cfn_shared_dir']}" do
  device dev_path
  fstype node['cfncluster']['cfn_volume_fs_type']
  options "_netdev"
  action [:mount, :enable]
end

# Get VPC CIDR
node.set['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block'] = get_vpc_ipv4_cidr_block(node['macaddress'])

# Export shared dir
nfs_export "#{node['cfncluster']['cfn_shared_dir']}" do
  network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
  writeable true 
  options ['no_root_squash']
end

# Export /home
nfs_export "/home" do
  network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
  writeable true
  options ['no_root_squash']
end

# Configure Ganglia on the Master
template '/etc/ganglia/gmetad.conf' do
  source 'gmetad.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

template '/etc/ganglia/gmond.conf' do
  source 'gmond.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

service "gmetad" do
  supports :restart => true
  action [ :enable, :start ]
end

service "gmond" do
  supports :restart => true
  action [ :enable, :start ]
end

service "httpd" do
  supports :restart => true
  action [ :enable, :start ]
end

# Setup cluster user
user "#{node['cfncluster']['cfn_cluster_user']}" do
  supports :manage_home => true
  comment 'cfncluster user'
  home "/home/#{node['cfncluster']['cfn_cluster_user']}"
  shell '/bin/bash'
end

# Setup SSH auth for cluster user
bash "ssh-keygen" do
  cwd "/home/#{node['cfncluster']['cfn_cluster_user']}"
  code <<-EOH
    su - #{node['cfncluster']['cfn_cluster_user']} -c \"ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''\"
  EOH
  not_if { ::File.exists?("/home/#{node['cfncluster']['cfn_cluster_user']}/.ssh/id_rsa") }
end

bash "copy_and_perms" do
  cwd "/home/#{node['cfncluster']['cfn_cluster_user']}"
  code <<-EOH
    su - #{node['cfncluster']['cfn_cluster_user']} -c \"cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys2 && chmod 0600 ~/.ssh/authorized_keys2\"
  EOH
  not_if { ::File.exists?("/home/#{node['cfncluster']['cfn_cluster_user']}/.ssh/authorized_keys2") }
end

bash "ssh-keyscan" do
  cwd "/home/#{node['cfncluster']['cfn_cluster_user']}"
  code <<-EOH
    su - #{node['cfncluster']['cfn_cluster_user']} -c \"ssh-keyscan #{node['hostname']} > ~/.ssh/known_hosts && chmod 0600 ~/.ssh/known_hosts\"
  EOH
  not_if { ::File.exists?("/home/#{node['cfncluster']['cfn_cluster_user']}/.ssh/known_hosts") }
end

# Install sqswatcher.cfg
template '/etc/sqswatcher.cfg' do
  source 'sqswatcher.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
