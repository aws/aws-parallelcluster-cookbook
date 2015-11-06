include_recipe 'cfncluster::base_install'

munge_tarball = "#{node['cfncluster']['sources_dir']}/munge-#{node['cfncluster']['slurm']['munge_version']}.tar.gz"
slurm_tarball = "#{node['cfncluster']['sources_dir']}/slurm-#{node['cfncluster']['slurm']['version']}.tar.gz"

# Get munge tarball
remote_file munge_tarball do
  source node['cfncluster']['slurm']['munge_url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(munge_tarball) }
end

# Install munge
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{munge_tarball}
    cd munge-munge-#{node['cfncluster']['slurm']['munge_version']}
    ./bootstrap
    ./configure --prefix=/usr --libdir=/usr/lib64
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/usr/bin/munge'
end

# Disable munge service
service "munge" do
  supports :restart => true
  action [ :disable, :stop ]
end

# Make sure the munge user exists
user("munge")

# Make sure /etc/munge directory exists
directory "/etc/munge" do
    action :create
end

# Create the munge key from template
template "/etc/munge/munge.key" do
    source "munge.key.erb"
    owner "munge"
end

# Get slurm tarball
remote_file slurm_tarball do
  source node['cfncluster']['slurm']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(slurm_tarball) }
end

# Install Slurm
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{slurm_tarball}
    cd slurm-slurm-#{node['cfncluster']['slurm']['version']}
    ./configure --prefix=/opt/slurm
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/slurm/bin/srun'
end
