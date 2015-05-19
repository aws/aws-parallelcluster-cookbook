include_recipe 'cfncluster::base_install'

torque_tarball = "#{node['cfncluster']['sources_dir']}/torque-#{node['cfncluster']['torque']['version']}.tar.gz"

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
    ./bootstrap
    ./configure --prefix=/opt/torque
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/torque/bin/pbsnodes'
end

