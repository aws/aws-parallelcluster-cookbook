slurm_install_dir = '/opt/slurm'
slurm_plugin_dir = '/etc/parallelcluster/slurm_plugin'

# Ensure slurm plugin directory is in place for tests that require it
directory slurm_plugin_dir do
  user 'root'
  group 'root'
  mode '0755'
  action :create
  recursive true
end

# skips the fake export on docker
return if on_docker?

directory slurm_install_dir do
  mode '1777'
end

nfs_export slurm_install_dir do
  network '127.0.0.1/32'
  writeable true
  options ['no_root_squash']
end
