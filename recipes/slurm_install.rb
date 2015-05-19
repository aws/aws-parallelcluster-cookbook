include_recipe 'cfncluster::base_install'

# Get munge tarball
remote_file "/opt/cfncluster/sources/munge.tar.gz" do
  source node['cfncluster']['slurm']['munge_url']
  mode '0644'
  # TODO: Add version or checksum checks
  not_if { ::File.exists?("/opt/cfncluster/sources/munge.tar.gz") }
end

# Install munge
bash 'make install' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-EOF
    tar xf /opt/cfncluster/sources/munge.tar.gz
    cd munge*
    ./bootstrap
    ./configure --prefix=/usr
    make install
  EOF
  # TODO: Fix, so it works for upgrade
  creates '/opt/torque/bin/pbsnodes'
end

