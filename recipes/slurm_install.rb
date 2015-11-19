include_recipe 'cfncluster::base_install'
include_recipe 'cfncluster::munge_install'

slurm_tarball = "#{node['cfncluster']['sources_dir']}/slurm-#{node['cfncluster']['slurm']['version']}.tar.gz"

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
