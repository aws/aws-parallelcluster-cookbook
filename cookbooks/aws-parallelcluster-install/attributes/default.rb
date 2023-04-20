# aws-parallelcluster-install attributes

# Default gc_thresh values for performance at scale
default['cluster']['sysctl']['ipv4']['gc_thresh1'] = 0
default['cluster']['sysctl']['ipv4']['gc_thresh2'] = 15_360
default['cluster']['sysctl']['ipv4']['gc_thresh3'] = 16_384

# Arm Performance Library
default['cluster']['armpl']['major_minor_version'] = '21.0'
default['cluster']['armpl']['patch_version'] = '0'
default['cluster']['armpl']['version'] = "#{node['cluster']['armpl']['major_minor_version']}.#{node['cluster']['armpl']['patch_version']}"

default['cluster']['armpl']['gcc']['major_minor_version'] = '9.3'
default['cluster']['armpl']['gcc']['patch_version'] = '0'
default['cluster']['armpl']['gcc']['url'] = [
  'https://ftp.gnu.org/gnu/gcc',
  "gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}",
  "gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}.tar.gz",
].join('/')
