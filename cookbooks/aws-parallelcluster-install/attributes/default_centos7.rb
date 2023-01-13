# Centos 7 default attributes for aws-parallelcluster-install

return unless platform?('centos') && node['platform_version'].to_i == 7

default['cluster']['base_packages'] = %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                         libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                         httpd boost-devel redhat-lsb mlocate lvm2 R atlas-devel
                                         blas-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                         libical-devel postgresql-devel postgresql-server sendmail libxml2-devel libglvnd-devel
                                         mdadm python python-pip libssh2-devel libgcrypt-devel libevent-devel glibc-static bind-utils
                                         iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
                                         coreutils moreutils sssd sssd-tools sssd-ldap curl)

# TODO: check if it is still relevant. Evaluate if it is worth to remove the package.
if node['kernel']['machine'] == 'aarch64'
  # Do not install bind-utils on centos7+arm due to issue with package checksum
  default['cluster']['base_packages'].delete('bind-utils')
end

default['cluster']['kernel_devel_pkg']['name'] = "kernel-devel"
# TODO: Evaluate to move the chomps where the attribute is used.
default['cluster']['kernel_devel_pkg']['version'] = node['kernel']['release'].chomp('.x86_64').chomp('.aarch64')

default['cluster']['chrony']['conf'] = "/etc/chrony.conf"
