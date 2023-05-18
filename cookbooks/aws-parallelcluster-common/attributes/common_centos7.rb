# Centos 7 common attributes shared between multiple cookbooks

return unless platform?('centos') && node['platform_version'].to_i == 7

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"

# NVIDIA
# NVIDIA GDRCopy
default['cluster']['nvidia']['gdrcopy']['version'] = '2.3'
default['cluster']['nvidia']['gdrcopy']['url'] = "https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v#{node['cluster']['nvidia']['gdrcopy']['version']}.tar.gz"
default['cluster']['nvidia']['gdrcopy']['sha256'] = 'b85d15901889aa42de6c4a9233792af40dd94543e82abe0439e544c87fd79475'
default['cluster']['nvidia']['gdrcopy']['service'] = 'gdrcopy'

# NVIDIA fabric-manager
# The package name of Fabric Manager for centos7 is nvidia-fabric-manager-version
default['cluster']['nvidia']['fabricmanager']['package'] = "nvidia-fabric-manager"
default['cluster']['nvidia']['fabricmanager']['repository_key'] = "D42D0685.pub"
default['cluster']['nvidia']['fabricmanager']['version'] = node['cluster']['nvidia']['driver_version']

# Nvidia Repository for fabricmanager and datacenter-gpu-manager
default['cluster']['nvidia']['cuda']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel7/#{arm_instance? ? 'sbsa' : 'x86_64'}"
