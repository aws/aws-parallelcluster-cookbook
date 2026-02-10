# Slurm
default['cluster']['slurm']['version'] = '25-11-2-1'
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['branch'] = ''
default['cluster']['slurm']['sha256'] = '719783317e46b6241ab5c8f1e3f91e1e34fda63b5a1cd21403fa7696ec8d517c'
default['cluster']['slurm']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/slurm"
# Munge
default['cluster']['munge']['munge_version'] = '0.5.18'
default['cluster']['munge']['sha256'] = '67722a4fbf46d206fa01061cd8832a04693d8a5d2699540b86528016de7efb55'
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
