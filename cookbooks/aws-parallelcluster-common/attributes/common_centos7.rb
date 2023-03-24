# Centos 7 common attributes shared between multiple cookbooks

return unless platform?('centos') && node['platform_version'].to_i == 7

# Modulefile Directory
default['cluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"
# MODULESHOME
default['cluster']['moduleshome'] = "/usr/share/Modules"
default['cluster']['modulepath_config_file'] = "#{node['cluster']['moduleshome']}/init/.modulespath"

default['cluster']['chrony']['service'] = "chronyd"

# NVIDIA
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '470.141.03'
default['cluster']['nvidia']['cuda_version'] = '11.7'
default['cluster']['nvidia']['cuda_samples_version'] = '11.6'
default['cluster']['nvidia']['driver_url_architecture_id'] = arm_instance? ? 'aarch64' : 'x86_64'
default['cluster']['nvidia']['cuda_url_architecture_id'] = arm_instance? ? 'linux_sbsa' : 'linux'
default['cluster']['nvidia']['driver_url'] = "https://us.download.nvidia.com/tesla/#{node['cluster']['nvidia']['driver_version']}/NVIDIA-Linux-#{node['cluster']['nvidia']['driver_url_architecture_id']}-#{node['cluster']['nvidia']['driver_version']}.run"
default['cluster']['nvidia']['cuda_url'] = "https://developer.download.nvidia.com/compute/cuda/11.7.1/local_installers/cuda_11.7.1_515.65.01_#{node['cluster']['nvidia']['cuda_url_architecture_id']}.run"
default['cluster']['nvidia']['cuda_samples_url'] = "https://github.com/NVIDIA/cuda-samples/archive/refs/tags/v#{node['cluster']['nvidia']['cuda_samples_version']}.tar.gz"

# NVIDIA GDRCopy
default['cluster']['nvidia']['gdrcopy']['version'] = '2.3'
default['cluster']['nvidia']['gdrcopy']['url'] = "https://github.com/NVIDIA/gdrcopy/archive/refs/tags/v#{node['cluster']['nvidia']['gdrcopy']['version']}.tar.gz"
default['cluster']['nvidia']['gdrcopy']['sha256'] = 'b85d15901889aa42de6c4a9233792af40dd94543e82abe0439e544c87fd79475'
default['cluster']['nvidia']['gdrcopy']['service'] = 'gdrcopy'

# NVIDIA fabric-manager
# The package name of Fabric Manager for alinux2 and centos7 is nvidia-fabric-manager-version
default['cluster']['nvidia']['fabricmanager']['package'] = "nvidia-fabric-manager"
default['cluster']['nvidia']['fabricmanager']['repository_key'] = "D42D0685.pub"
default['cluster']['nvidia']['fabricmanager']['version'] = node['cluster']['nvidia']['driver_version']
default['cluster']['nvidia']['fabricmanager']['repository_uri'] = "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel7/x86_64"
