# Slurm
default['cluster']['slurm']['version'] = '25-11-2-1'
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['branch'] = ''
default['cluster']['slurm']['sha256'] = '719783317e46b6241ab5c8f1e3f91e1e34fda63b5a1cd21403fa7696ec8d517c'
default['cluster']['slurm']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/slurm"
# Munge
default['cluster']['munge']['munge_version'] = '0.5.17'
default['cluster']['munge']['sha256'] = '4d6a1b9665d8a1119fb90678e6bcf446012340dc59dbcc90a10e2ab2e4724f08'
if platform?('amazon') && node['platform_version'] == "2"
  default['cluster']['munge']['munge_version'] = '0.5.16'
  default['cluster']['munge']['sha256'] = 'fa27205d6d29ce015b0d967df8f3421067d7058878e75d0d5ec3d91f4d32bb57'
end
default['cluster']['munge']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/munge"
# LibJwt
default['cluster']['jwt']['version'] = '1.18.4'
default['cluster']['jwt']['sha256'] = '8496257cb39ee7dddfdfc919e7b80a997399b0319f9fdcbefd374b0e4f147159'
if platform?('amazon') && node['platform_version'] == "2"
  default['cluster']['jwt']['version'] = '1.17.0'
  default['cluster']['jwt']['sha256'] = '617778f9687682220abf9b7daacbe72bab7c2985479f8bee4db9648bd2440687'
end
default['cluster']['jwt']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/jwt"
## MySql
default['cluster']['mysql']['source_version'] = '8.4.8'
if platform?('amazon') && node['platform_version'] == "2"
  default['cluster']['mysql']['source_version'] = '8.0.39'
end
default['cluster']['mysql']['version'] = "#{node['cluster']['mysql']['source_version']}-1"
default['cluster']['mysql']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/mysql"
