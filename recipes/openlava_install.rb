include_recipe 'cfncluster::base_install'

openlava_tarball = "#{node['cfncluster']['sources_dir']}/openlava-#{node['cfncluster']['openlava']['version']}.tar.gz"

# Get Openlava tarball
remote_file openlava_tarball do
  source node['cfncluster']['openlava']['url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?(openlava_tarball) }
end

# Install Openlava
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf #{openlava_tarball}
    cd openlava-#{node['cfncluster']['openlava']['version']}
    ./bootstrap.sh
    ./configure --prefix=/opt/openlava
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/openlava/bin/lsid'
end

# Install openlava-python bindings
python_pip 'cython'

