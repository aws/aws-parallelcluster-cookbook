# Ubuntu 20 default attributes for aws-parallelcluster-install

return unless platform?('ubuntu') && node['platform_version'] == "22.04"

# environment-modules required by EFA, Intel MPI and ARM PL
# iptables needed for IMDS setup
default['cluster']['base_packages'] = %w(vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
                                         tcl-dev automake autoconf libtool librrd-dev libapr1-dev libconfuse-dev
                                         apache2 libboost-dev libdb-dev libncurses5-dev libpam0g-dev libxt-dev
                                         libmotif-dev libxmu-dev libxft-dev man-db python
                                         r-base libblas-dev libffi-dev libxml2-dev mdadm
                                         libgcrypt20-dev libevent-dev iproute2 python3 python3-pip
                                         libatlas-base-dev libglvnd-dev iptables libcurl4-openssl-dev
                                         coreutils moreutils curl python3-parted environment-modules)

default['cluster']['kernel_headers_pkg'] = "linux-headers-#{node['kernel']['release']}"

default['cluster']['chrony']['conf'] = "/etc/chrony/chrony.conf"

default['nfs']['service_provider']['idmap'] = Chef::Provider::Service::Systemd
default['nfs']['service_provider']['portmap'] = Chef::Provider::Service::Systemd
default['nfs']['service_provider']['lock'] = Chef::Provider::Service::Systemd
default['nfs']['service']['lock'] = 'rpc-statd'
default['nfs']['service']['idmap'] = 'nfs-idmapd'
