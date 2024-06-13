# Slurm
default['cluster']['slurm']['version'] = '23-11-7-1'
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['branch'] = ''
default['cluster']['slurm']['sha256'] = 'b25127efd69a47c14bd65dfa3bff2687b5350c5290eafb601f923faebe6fd238'
default['cluster']['slurm']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/slurm"
# Munge
default['cluster']['munge']['munge_version'] = '0.5.15'
default['cluster']['munge']['sha256'] = '51b2c81d1a7ec2ab5d486fa51b50c7e79eb1810ca6687b6ed65f3601abc55614'
default['cluster']['munge']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/munge"
