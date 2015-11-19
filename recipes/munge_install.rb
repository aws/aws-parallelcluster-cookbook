include_recipe 'cfncluster::base_install'

munge_tarball = "#{node['cfncluster']['sources_dir']}/munge-#{node['cfncluster']['munge']['munge_version']}.tar.gz"

# Get munge tarball
remote_file munge_tarball do
  source node['cfncluster']['munge']['munge_url']
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
    cd munge-munge-#{node['cfncluster']['munge']['munge_version']}
    ./bootstrap
    ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/usr/bin/munge'
  not_if "/usr/sbin/munged --version | grep -q munge-#{node['cfncluster']['munge']['munge_version']}"
end

# Make sure the munge user exists
user("munge")

# Mown munge /var/log/munge/ke sure /etc/munge directory exists
directory "/var/log/munge" do
    action :create
    owner "munge"
end

# Mown munge /var/log/munge/ke sure /etc/munge directory exists
directory "/etc/munge" do
    action :create
    owner "munge"
end

# Mown munge /var/log/munge/ke sure /etc/munge directory exists
directory "/var/run/munge" do
    action :create
    owner "munge"
end

# Create the munge key from template
template "/etc/munge/munge.key" do
    source "munge.key.erb"
    owner "munge"
    mode "0600"
end

# Enable munge service
service "munge" do
  supports :restart => true
  action [ :enable, :start ]
end

