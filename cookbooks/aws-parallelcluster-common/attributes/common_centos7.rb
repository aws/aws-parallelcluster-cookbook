# Centos 7 common attributes shared between multiple cookbooks

return unless platform?('centos') && node['platform_version'].to_i == 7

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"

# Nvidia Repository for fabricmanager and datacenter-gpu-manager
default['cluster']['nvidia']['cuda']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel7/#{arm_instance? ? 'sbsa' : 'x86_64'}"
