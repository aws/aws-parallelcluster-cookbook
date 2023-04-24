# Ubuntu 18 common attributes shared between multiple cookbooks

return unless platform?('ubuntu') && node['platform_version'] == "18.04"

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"
# MODULESHOME
default['cluster']['moduleshome'] = "/usr/share/modules"
# Config file used to set default MODULEPATH list
default['cluster']['modulepath_config_file'] = "#{node['cluster']['moduleshome']}/init/.modulespath"

default['cluster']['chrony']['service'] = "chrony"

# NVIDIA
# NVIDIA GDRCopy
default['cluster']['nvidia']['gdrcopy']['version'] = '2.3'
default['cluster']['nvidia']['gdrcopy']['url'] = "https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v#{node['cluster']['nvidia']['gdrcopy']['version']}.tar.gz"
default['cluster']['nvidia']['gdrcopy']['sha256'] = 'b85d15901889aa42de6c4a9233792af40dd94543e82abe0439e544c87fd79475'
default['cluster']['nvidia']['gdrcopy']['service'] = 'gdrdrv'

# NVIDIA fabric-manager
# The package name of Fabric Manager for ubuntu is nvidia-fabricmanager-470_version
default['cluster']['nvidia']['fabricmanager']['package'] = "nvidia-fabricmanager-470"
default['cluster']['nvidia']['fabricmanager']['repository_key'] = "3bf863cc.pub"
# with apt a star is needed to match the package version
default['cluster']['nvidia']['fabricmanager']['version'] = "#{node['cluster']['nvidia']['driver_version']}*"

# Nvidia Repository for fabricmanager and datacenter-gpu-manager
default['cluster']['nvidia']['cuda']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/#{node['cluster']['base_os']}/#{arm_instance? ? 'sbsa' : 'x86_64'}"
