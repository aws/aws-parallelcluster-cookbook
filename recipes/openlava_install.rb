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

# Install Openlava config files
for cfile in [ "lsf.conf", "lsb.hosts", "lsb.params", "lsb.queues", "lsb.users", "lsf.cluster.openlava", "lsf.shared", "lsf.task", "openlava.csh", "openlava.setup", "openlava.sh" ] do
  bash "copy #{cfile}" do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-EOF
      cd openlava-#{node['cfncluster']['openlava']['version']}/config
      cp #{cfile} /opt/openlava/etc
    EOF
    creates "/opt/openlava/etc/#{cfile}"
  end
end

# Setup openlava user
  user "openlava" do
  supports :manage_home => true
  comment 'openlava user'
  home "/home/openlava"
  system true
  shell '/bin/bash'
end

# Set ownership of /opt/openlava to openlava user
execute 'chown' do
  command 'chown -R openlava:openlava /opt/openlava'
end

# Install openlava-python bindings
python_pip 'cython'

