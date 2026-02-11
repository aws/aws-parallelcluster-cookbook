# Slurm
default['cluster']['slurm']['version'] = '24-11-7-1'
default['cluster']['slurm']['commit'] = ''
default['cluster']['slurm']['branch'] = ''
default['cluster']['slurm']['sha256'] = 'f0912d85a9a9b417fd23ca4997c8d3dfed89b3b70b15aad4da54f2812d30d48c'
default['cluster']['slurm']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/slurm"
# Munge
default['cluster']['munge']['munge_version'] = '0.5.18'
default['cluster']['munge']['sha256'] = '39c3ec6ef5604bfa206e8aa10fc05d5119040f6de4a554bc0fb98ca1aed838dc'
default['cluster']['munge']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/munge"
# LibJwt
default['cluster']['jwt']['version'] = '1.18.4'
default['cluster']['jwt']['sha256'] = '8496257cb39ee7dddfdfc919e7b80a997399b0319f9fdcbefd374b0e4f147159'
if platform?('amazon') && node['platform_version'] == "2"
  default['cluster']['jwt']['version'] = '1.17.0'
  default['cluster']['jwt']['sha256'] = '617778f9687682220abf9b7daacbe72bab7c2985479f8bee4db9648bd2440687'
end
default['cluster']['jwt']['base_url'] = "#{node['cluster']['artifacts_s3_url']}/dependencies/jwt"
