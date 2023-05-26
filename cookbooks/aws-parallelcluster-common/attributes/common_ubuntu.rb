# Ubuntu common attributes shared between multiple cookbooks

return unless platform?('ubuntu')

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"

# NVIDIA
# NVIDIA GDRCopy
default['cluster']['nvidia']['gdrcopy']['version'] = '2.3'
default['cluster']['nvidia']['gdrcopy']['url'] = "https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v#{node['cluster']['nvidia']['gdrcopy']['version']}.tar.gz"
default['cluster']['nvidia']['gdrcopy']['sha256'] = 'b85d15901889aa42de6c4a9233792af40dd94543e82abe0439e544c87fd79475'
default['cluster']['nvidia']['gdrcopy']['service'] = 'gdrdrv'

# Nvidia Repository for fabricmanager and datacenter-gpu-manager
default['cluster']['nvidia']['cuda']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/#{node['cluster']['base_os']}/#{arm_instance? ? 'sbsa' : 'x86_64'}"
