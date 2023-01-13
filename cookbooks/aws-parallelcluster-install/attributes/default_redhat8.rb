# RedHat 8 default attributes for aws-parallelcluster-install

return unless platform?('redhat') && node['platform_version'].to_i == 8

default['cluster']['kernel_devel_pkg']['name'] = "kernel-devel"
default['cluster']['kernel_devel_pkg']['version'] = node['kernel']['release'].chomp('.x86_64').chomp('.aarch64')

# Removed libssh2-devel from base_packages since is not shipped by RedHat 8 and in conflict with package libssh-0.9.6-3.el8.x86_64
default['cluster']['base_packages'] = %w(vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                             libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                             httpd boost-devel redhat-lsb mlocate lvm2 R atlas-devel
                                             blas-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                             libical-devel postgresql-devel postgresql-server sendmail libxml2-devel libglvnd-devel
                                             mdadm python2 python2-pip libgcrypt-devel libevent-devel glibc-static bind-utils
                                             iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel yum-plugin-versionlock
                                             coreutils moreutils sssd sssd-tools sssd-ldap curl)

# Needed by hwloc-devel blas-devel libedit-devel and glibc-static packages
default['cluster']['extra_repos'] = 'codeready-builder-for-rhel-8-rhui-rpms'

default['cluster']['kernel_devel_pkg']['name'] = "kernel-devel"
default['cluster']['kernel_devel_pkg']['version'] = node['kernel']['release'].chomp('.x86_64').chomp('.aarch64')

default['cluster']['chrony']['conf'] = "/etc/chrony.conf"
