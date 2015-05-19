# Base dir
default['cfncluster']['base_dir'] = '/opt/cfncluster'
default['cfncluster']['sources_dir'] = "#{node['cfncluster']['base_dir']}/sources"
# URLs to software packages used during install receipes
default['cfncluster']['udev_url'] = 'https://github.com/awslabs/ec2-udev-scripts/archive/v0.1.0.tar.gz'
# Gridengine software
default['cfncluster']['sge']['version'] = '8.1.8'
default['cfncluster']['sge']['url'] = 'http://arc.liv.ac.uk/downloads/SGE/releases/8.1.8/sge-8.1.8.tar.gz'
# Openlava software
default['cfncluster']['openlava']['version'] = '3.0'
default['cfncluster']['openlava']['url'] = 'https://github.com/openlava/openlava/archive/3.0.tar.gz'
# Torque software
default['cfncluster']['torque']['version'] = '4.2.9'
default['cfncluster']['torque']['url'] = 'http://www.adaptivecomputing.com/index.php?wpfb_dl=2849'

default['cfncluster']['slurm']['version'] = '14.11.5'
default['cfncluster']['slurm']['url'] = 'https://github.com/SchedMD/slurm/archive/slurm-14-11-5-1.tar.gz'
default['cfncluster']['slurm']['munge_url'] = 'https://munge.googlecode.com/files/munge-0.5.11.tar.bz2'

# Ganglia
default['cfncluster']['ganglia']['version'] = '3.6.1'
default['cfncluster']['ganglia']['url'] = 'http://downloads.sourceforge.net/project/ganglia/ganglia%20monitoring%20core/3.6.1/ganglia-3.6.1.tar.gz?r=&ts=1426042631&use_mirror=hivelocity'
default['cfncluster']['ganglia']['web_version'] = '3.6.2'
default['cfncluster']['ganglia']['web_url'] = 'http://downloads.sourceforge.net/project/ganglia/ganglia-web/3.6.2/ganglia-web-3.6.2.tar.gz?r=&ts=1426042690&use_mirror=hivelocity'

# Default packages are for CentOS6
default['cfncluster']['base_packages'] = %w(ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool)

# Update for NFS on Amazon Linux
case node['platform']
when 'amazon'
  default['nfs']['packages'] = %w(nfs-utils rpcbind)
  default['nfs']['service']['portmap'] = 'rpcbind'
  default['nfs']['service']['lock'] = 'nfslock'
  default['nfs']['service']['server'] = 'nfs'
  default['nfs']['service']['idmap'] = 'rpcidmapd'
end

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
