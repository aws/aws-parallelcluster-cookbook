# Slurm
default['cluster']['slurm']['version'] = '24-05-8-1'
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['branch'] = ''
default['cluster']['slurm']['sha256'] = '06f4b837c3f7ec523a8924a5fee23d8305f20ca8ef3ad6128e128e87986821e4'
default['cluster']['slurm']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/slurm"
# Munge
default['cluster']['munge']['munge_version'] = '0.5.16'
default['cluster']['munge']['sha256'] = 'fa27205d6d29ce015b0d967df8f3421067d7058878e75d0d5ec3d91f4d32bb57'
default['cluster']['munge']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/munge"
