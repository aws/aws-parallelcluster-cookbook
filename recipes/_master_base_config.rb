#
# Cookbook Name:: aws-parallelcluster
# Recipe:: _master_base_config
#
# Copyright 2013-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

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

# Get VPC CIDR
node.default['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block'] = get_vpc_ipv4_cidr_block(node['macaddress'])

# Mount EFS directory with efs_mount recipe
include_recipe 'aws-parallelcluster::efs_mount'

# Parse shared directory info and turn into an array
shared_dir_array = node['cfncluster']['cfn_shared_dir'].split(',')
shared_dir_array.each_with_index do |dir, index|
  shared_dir_array[index] = dir.strip
  shared_dir_array[index] = "/" + shared_dir_array[index]
end

# Parse volume info into an arary
vol_array = node['cfncluster']['cfn_volume'].split(',')
vol_array.each_with_index do |vol, index|
  vol_array[index] = vol.strip
end

# Mount each volume
dev_path = []

vol_array.each_with_index do |volumeid, index|
  dev_path[index] = "/dev/disk/by-ebs-volumeid/#{volumeid}"

  # Attach EBS volume
  execute "attach_volume_#{index}" do
    command "/usr/local/sbin/attachVolume.py #{volumeid}"
    creates dev_path[index]
  end

  # wait for the drive to attach, before making a filesystem
  ruby_block "sleeping_for_volume_#{index}" do
    block do
      wait_for_block_dev(dev_path[index])
    end
    action :nothing
    subscribes :run, "execute[attach_volume_#{index}]", :immediately
  end

  # Setup disk, will be formatted xfs if empty
  ruby_block "setup_disk_#{index}" do
    block do
      fs_type = setup_disk(dev_path[index])
      node.default['cfncluster']['cfn_volume_fs_type'] = fs_type
    end
    action :nothing
    subscribes :run, "ruby_block[sleeping_for_volume_#{index}]", :immediately
  end

  # Create the shared directories
  directory shared_dir_array[index] do
    owner 'root'
    group 'root'
    mode '1777'
    recursive true
    action :create
  end

  # Add volume to /etc/fstab
  mount shared_dir_array[index] do
    device dev_path[index]
    fstype(DelayedEvaluator.new { node['cfncluster']['cfn_volume_fs_type'] })
    options "_netdev"
    pass 0
    action %i[mount enable]
  end

  # Make sure shared directory permissions are correct
  directory shared_dir_array[index] do
    owner 'root'
    group 'root'
    mode '1777'
  end

  # Export shared dir
  nfs_export shared_dir_array[index] do
    network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
    writeable true
    options ['no_root_squash']
  end
end

# Export /home
nfs_export "/home" do
  network node['cfncluster']['ec2-metadata']['vpc-ipv4-cidr-block']
  writeable true
  options ['no_root_squash']
end


# Setup RAID array on master node
include_recipe 'aws-parallelcluster::setup_raid_on_master'

# Only run FSx on centos for now
if node['platform'] == 'centos'
  # Install FSx
  include_recipe 'aws-parallelcluster::mount_fsx'
end

# Configure Ganglia on the Master
if node['cfncluster']['ganglia_enabled'] == 'yes'
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
    supports restart: true
    action %i[enable restart]
  end

  service node['cfncluster']['ganglia']['gmond_service'] do
    supports restart: true
    action %i[enable restart]
  end

  service node['cfncluster']['ganglia']['httpd_service'] do
    supports restart: true
    action %i[enable start]
  end
end

# Setup cluster user
user node['cfncluster']['cfn_cluster_user'] do
  manage_home true
  comment 'cfncluster user'
  home "/home/#{node['cfncluster']['cfn_cluster_user']}"
  shell '/bin/bash'
end

# Setup SSH auth for cluster user
bash "ssh-keygen" do
  cwd "/home/#{node['cfncluster']['cfn_cluster_user']}"
  code <<-KEYGEN
    su - #{node['cfncluster']['cfn_cluster_user']} -c \"ssh-keygen -q -t rsa -f ~/.ssh/id_rsa -N ''\"
  KEYGEN
  not_if { ::File.exist?("/home/#{node['cfncluster']['cfn_cluster_user']}/.ssh/id_rsa") }
end

bash "copy_and_perms" do
  cwd "/home/#{node['cfncluster']['cfn_cluster_user']}"
  code <<-PERMS
    su - #{node['cfncluster']['cfn_cluster_user']} -c \"cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys2 && chmod 0600 ~/.ssh/authorized_keys2\"
  PERMS
  not_if { ::File.exist?("/home/#{node['cfncluster']['cfn_cluster_user']}/.ssh/authorized_keys2") }
end

bash "ssh-keyscan" do
  cwd "/home/#{node['cfncluster']['cfn_cluster_user']}"
  code <<-KEYSCAN
    su - #{node['cfncluster']['cfn_cluster_user']} -c \"ssh-keyscan #{node['hostname']} > ~/.ssh/known_hosts && chmod 0600 ~/.ssh/known_hosts\"
  KEYSCAN
  not_if { ::File.exist?("/home/#{node['cfncluster']['cfn_cluster_user']}/.ssh/known_hosts") }
end

# Install jobwatcher.cfg
template '/etc/jobwatcher.cfg' do
  source 'jobwatcher.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# Install sqswatcher.cfg
template '/etc/sqswatcher.cfg' do
  source 'sqswatcher.cfg.erb'
  owner 'root'
  group 'root'
  mode '0644'
end
