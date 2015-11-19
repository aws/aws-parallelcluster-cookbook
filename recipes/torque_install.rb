include_recipe 'cfncluster::base_install'
include_recipe 'cfncluster::munge_install'

torque_tarball = "#{node['cfncluster']['sources_dir']}/torque-#{node['cfncluster']['torque']['version']}.tar.gz"

# Install packages required to build torque
node['cfncluster']['torque_packages'].each do |p|
  package p
end

# Get Torque tarball
remote_file torque_tarball do
  source node['cfncluster']['torque']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(torque_tarball) }
end

# Install Torque
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{torque_tarball}
    cd torque-#{node['cfncluster']['torque']['version']}
    ./autogen.sh
    ./configure --prefix=/opt/torque --enable-munge-auth
    make install
    cp -vpR contrib /opt/torque
  EOF
  # Only perform if running version doesn't match desired
  not_if "/opt/torque/bin/pbsnodes --version 2>&1 | grep -q #{node['cfncluster']['torque']['version']}"
  creates "/random/path"
end

directory '/opt/torque/bin/' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

directory '/var/spool/torque' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# Modified torque.setup
cookbook_file 'torque.setup' do
  path '/opt/torque/bin/torque.setup'
  user 'root'
  group 'root'
  mode '0755'
end  
