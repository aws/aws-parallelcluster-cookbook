return if on_docker?

slurm_install_dir = '/opt/slurm'
directory slurm_install_dir do
  mode '1777'
end

nfs_export slurm_install_dir do
  network '127.0.0.1/32'
  writeable true
  options ['no_root_squash']
end
