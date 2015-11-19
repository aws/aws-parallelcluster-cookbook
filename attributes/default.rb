# Base dir
default['cfncluster']['base_dir'] = '/opt/cfncluster'
default['cfncluster']['sources_dir'] = "#{node['cfncluster']['base_dir']}/sources"
default['cfncluster']['scripts_dir'] = "#{node['cfncluster']['base_dir']}/scripts"
# URLs to software packages used during install receipes
default['cfncluster']['udev_url'] = 'https://github.com/awslabs/ec2-udev-scripts/archive/v0.1.0.tar.gz'
# Gridengine software
default['cfncluster']['sge']['version'] = '8.1.8'
default['cfncluster']['sge']['url'] = 'http://arc.liv.ac.uk/downloads/SGE/releases/8.1.8/sge-8.1.8.tar.gz'
# Openlava software
default['cfncluster']['openlava']['version'] = '3.1'
default['cfncluster']['openlava']['url'] = 'https://github.com/openlava/openlava/archive/3.1.tar.gz'
# Torque software
default['cfncluster']['torque']['version'] = '6.0.0'
default['cfncluster']['torque']['url'] = 'https://github.com/adaptivecomputing/torque/archive/6.0.0.tar.gz'
# Slurm software
default['cfncluster']['slurm']['version'] = '15-08-2-1'
default['cfncluster']['slurm']['url'] = 'https://github.com/SchedMD/slurm/archive/slurm-15-08-2-1.tar.gz'
# Munge
default['cfncluster']['munge']['munge_version'] = '0.5.11'
default['cfncluster']['munge']['munge_url'] = 'https://github.com/dun/munge/archive/munge-0.5.11.tar.gz'

# Ganglia
default['cfncluster']['ganglia']['version'] = '3.6.1'
default['cfncluster']['ganglia']['url'] = 'http://downloads.sourceforge.net/project/ganglia/ganglia%20monitoring%20core/3.6.1/ganglia-3.6.1.tar.gz?r=&ts=1426042631&use_mirror=hivelocity'
default['cfncluster']['ganglia']['web_version'] = '3.6.2'
default['cfncluster']['ganglia']['web_url'] = 'http://downloads.sourceforge.net/project/ganglia/ganglia-web/3.6.2/ganglia-web-3.6.2.tar.gz?r=&ts=1426042690&use_mirror=hivelocity'

# Platform defaults
case node['platform_family']

when 'rhel'
  case node['platform']

  when 'centos', 'rhel'
    default['cfncluster']['base_packages'] = %w(ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool httpd boost-devel redhat-lsb)
    default['cfncluster']['torque_packages'] = %w(boost boost-devel)
    if node['platform_version'].to_i >= 7
    default['cfncluster']['torque_packages'] = %w(boost boost-devel)
    default['cfncluster']['base_packages'] = %w(ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool httpd boost-devel redhat-lsb)
    end
  when 'amazon'
    default['cfncluster']['torque_packages'] = %w(boost boost-devel)
    default['cfncluster']['base_packages'] = %w(ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool httpd boost-devel redhat-lsb)

  end

  default['cfncluster']['ganglia']['apache_user'] = 'apache'
  default['cfncluster']['ganglia']['gmond_service'] = 'gmond'
  default['cfncluster']['ganglia']['httpd_service'] = 'httpd'
  default['cfncluster']['torque']['trqauthd_source'] = 'file:///opt/torque/contrib/init.d/trqauthd'
  default['cfncluster']['torque']['pbs_mom_source'] = 'file:///opt/torque/contrib/init.d/pbs_mom'
  default['cfncluster']['torque']['pbs_sched_source'] = 'file:///opt/torque/contrib/init.d/pbs_sched'
  default['cfncluster']['torque']['pbs_server_source'] = 'file:///opt/torque/contrib/init.d/pbs_server'

when 'debian'
  default['cfncluster']['torque_packages'] = %w(munge libmunge-dev boost boost-dev)
  default['cfncluster']['base_packages'] = %w(ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libXmu-dev libhwloc-dev tcl-dev automake autoconf python-parted libtool librrd-dev libapr1-dev libconfuse-dev apache2 libboost-dev libdb-dev tcsh libssl-dev  libncurses5-dev libpam0g-dev libxt-dev libmotif-dev libxmu-dev libxft-dev libhwloc-dev man-db)
  default['cfncluster']['ganglia']['apache_user'] = 'www-data'
  default['cfncluster']['ganglia']['gmond_service'] = 'ganglia-monitor'
  default['cfncluster']['ganglia']['httpd_service'] = 'apache2'
  default['cfncluster']['torque']['trqauthd_source'] = 'file:///opt/torque/contrib/init.d/debian.trqauthd'
  default['cfncluster']['torque']['pbs_mom_source'] = 'file:///opt/torque/contrib/init.d/debian.pbs_mom'
  default['cfncluster']['torque']['pbs_sched_source'] = 'file:///opt/torque/contrib/init.d/debian.pbs_sched'
  default['cfncluster']['torque']['pbs_server_source'] = 'file:///opt/torque/contrib/init.d/debian.pbs_server'
end

# Update for NFS on Amazon Linux
case node['platform']
when 'amazon'
  default['nfs']['packages'] = %w(nfs-utils rpcbind)
  default['nfs']['service']['portmap'] = 'rpcbind'
  default['nfs']['service']['lock'] = 'nfslock'
  default['nfs']['service']['server'] = 'nfs'
  default['nfs']['service']['idmap'] = 'rpcidmapd'
  default['nfs']['client-services'] = %w(portmap lock)
end

# OpenSSH settings for CfnCluster instances
default['openssh']['server']['protocol'] = '2'
default['openssh']['server']['syslog_facility'] = 'AUTHPRIV'
default['openssh']['server']['permit_root_login'] = 'forced-commands-only'
default['openssh']['server']['password_authentication'] = 'no'
default['openssh']['server']['gssapi_authentication'] = 'yes'
default['openssh']['server']['gssapi_clean_up_credentials'] = 'yes'
default['openssh']['server']['x11_forwarding'] = 'yes'
default['openssh']['server']['subsystem'] = 'sftp /usr/libexec/sftp-server'
default['openssh']['client']['gssapi_authentication'] = 'yes'

# Munge key
default['cfncluster']['munge']['munge_key'] = 'YflQEFLjoxsmEK5vQyKklkLKJ#LkjLKDJF@*(#)ajLKQ@hLKN#()FSU(#@KLJH$@HKSASG)*DUJJDksdN'


# cfncluster variables (also in /etc/cfncluster/cfnconfig)
default['cfncluster']['cfn_region'] = 'us-east-1'
default['cfncluster']['stack_name'] = nil
default['cfncluster']['cfn_sqs_queue'] = nil
default['cfncluster']['cfn_ddb_table'] = nil
default['cfncluster']['cfn_node_type'] = nil
default['cfncluster']['cfn_preinstall'] = 'NONE'
default['cfncluster']['cfn_preinstall_args'] = 'NONE'
default['cfncluster']['cfn_postinstall'] = 'NONE'
default['cfncluster']['cfn_postinstall_args'] = 'NONE'
default['cfncluster']['cfn_scheduler'] = 'sge'
default['cfncluster']['cfn_volume'] = nil
default['cfncluster']['cfn_volume_fs_type'] = 'ext4'
default['cfncluster']['cfn_encrypted_ephemeral'] = false
default['cfncluster']['cfn_ephemeral_dir'] = '/scratch'
default['cfncluster']['cfn_shared_dir'] = '/shared'
default['cfncluster']['cfn_node_type'] = nil
default['cfncluster']['cfn_master'] = nil
default['cfncluster']['cfn_cluster_user'] = 'ec2-user'
