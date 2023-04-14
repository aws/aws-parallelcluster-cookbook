# Ubuntu 18 default attributes for aws-parallelcluster-install

return unless platform?('ubuntu') && node['platform_version'] == "18.04"

# environment-modules required by EFA, Intel MPI and ARM PL
# iptables needed for IMDS setup
default['cluster']['base_packages'] = %w(vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
                                         tcl-dev automake autoconf libtool librrd-dev libapr1-dev libconfuse-dev
                                         apache2 libboost-dev libdb-dev libncurses5-dev libpam0g-dev libxt-dev
                                         libmotif-dev libxmu-dev libxft-dev man-db python
                                         r-base libblas-dev libffi-dev libxml2-dev mdadm
                                         libgcrypt20-dev libevent-dev iproute2 python3 python3-pip
                                         libatlas-base-dev libglvnd-dev iptables libcurl4-openssl-dev
                                         coreutils moreutils curl
                                         python-pip python-parted environment-modules)

default['cluster']['kernel_headers_pkg'] = "linux-headers-#{node['kernel']['release']}"

default['cluster']['chrony']['conf'] = "/etc/chrony/chrony.conf"

default['nfs']['service_provider']['idmap'] = Chef::Provider::Service::Systemd
default['nfs']['service_provider']['portmap'] = Chef::Provider::Service::Systemd
default['nfs']['service_provider']['lock'] = Chef::Provider::Service::Systemd
default['nfs']['service']['lock'] = 'rpc-statd'
default['nfs']['service']['idmap'] = 'nfs-idmapd'

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
default['cluster']['armpl']['platform'] = 'Ubuntu-18.04'
default['cluster']['armpl']['url'] = [
  'archives/armpl',
  node['cluster']['armpl']['platform'],
  "arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}_gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.tar",
].join('/')
