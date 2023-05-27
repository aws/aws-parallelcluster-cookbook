# RedHat 8 common attributes shared between multiple cookbooks

return unless platform?('redhat') && node['platform_version'].to_i == 8

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"

# Nvidia Repository for fabricmanager and datacenter-gpu-manager
default['cluster']['nvidia']['cuda']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel8/#{arm_instance? ? 'sbsa' : 'x86_64'}"
