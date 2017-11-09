#
# Cookbook Name:: cfncluster
# Attributes:: default
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Base dir
default['cfncluster']['base_dir'] = '/opt/cfncluster'
default['cfncluster']['sources_dir'] = "#{node['cfncluster']['base_dir']}/sources"
default['cfncluster']['scripts_dir'] = "#{node['cfncluster']['base_dir']}/scripts"
default['cfncluster']['license_dir'] = "#{node['cfncluster']['base_dir']}/licenses"
# Python packages
default['cfncluster']['cfncluster-node-version'] = '1.4.1'
default['cfncluster']['cfncluster-supervisor-version'] = '3.3.1'
# URLs to software packages used during install receipes
# Gridengine software
default['cfncluster']['sge']['version'] = '8.1.9'
default['cfncluster']['sge']['url'] = 'https://arc.liv.ac.uk/downloads/SGE/releases/8.1.9/sge-8.1.9.tar.gz'
# Torque software
default['cfncluster']['torque']['version'] = '6.0.2'
default['cfncluster']['torque']['url'] = 'https://github.com/adaptivecomputing/torque/archive/6.0.2.tar.gz'
# Slurm software
default['cfncluster']['slurm']['version'] = '16-05-3-1'
default['cfncluster']['slurm']['url'] = 'https://github.com/SchedMD/slurm/archive/slurm-16-05-3-1.tar.gz'
# Munge
default['cfncluster']['munge']['munge_version'] = '0.5.12'
default['cfncluster']['munge']['munge_url'] = 'https://github.com/dun/munge/archive/munge-0.5.12.tar.gz'
# Ganglia
default['cfncluster']['ganglia']['version'] = '3.7.2'
default['cfncluster']['ganglia']['url'] = 'https://github.com/ganglia/monitor-core/archive/3.7.2.tar.gz'
default['cfncluster']['ganglia']['web_version'] = '3.7.2'
default['cfncluster']['ganglia']['web_url'] = 'https://github.com/ganglia/ganglia-web/archive/3.7.2.tar.gz'
# NVIDIA
default['cfncluster']['nvidia']['enabled'] = 'no'
default['cfncluster']['nvidia']['driver_url'] = 'http://us.download.nvidia.com/XFree86/Linux-x86_64/384.98/NVIDIA-Linux-x86_64-384.98.run'
default['cfncluster']['nvidia']['cuda_url'] = 'https://developer.nvidia.com/compute/cuda/9.0/Prod/local_installers/cuda_9.0.176_384.81_linux-run'

# OpenSSH settings for CfnCluster instances
default['openssh']['server']['protocol'] = '2'
default['openssh']['server']['syslog_facility'] = 'AUTHPRIV'
default['openssh']['server']['permit_root_login'] = 'forced-commands-only'
default['openssh']['server']['password_authentication'] = 'no'
default['openssh']['server']['gssapi_authentication'] = 'yes'
default['openssh']['server']['gssapi_clean_up_credentials'] = 'yes'
default['openssh']['server']['x11_forwarding'] = 'yes'
default['openssh']['server']['subsystem'] = 'sftp /usr/libexec/openssh/sftp-server'
default['openssh']['client']['gssapi_authentication'] = 'yes'

# Platform defaults
case node['platform_family']
when 'rhel'

  default['cfncluster']['kernel_devel_pkg']['name'] = "kernel-devel"
  default['cfncluster']['kernel_devel_pkg']['version'] = node['kernel']['release'].chomp!('.x86_64')

  case node['platform']
  when 'centos', 'redhat', 'scientific' # ~FC024
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate mpich-devel openmpi-devel R atlas-devel
                                                blas-devel fftw-devel libffi-devel openssl-devel dkms mysql-devel libedit-devel
                                                libical-devel postgresql-devel postgresql-server sendmail]
    if node['platform_version'].to_i >= 7
      default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                  libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                                  httpd boost-devel redhat-lsb mlocate lvm2 mpich-devel openmpi-devel R atlas-devel
                                                  blas-devel fftw-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                                  libical-devel postgresql-devel postgresql-server sendmail libxml2-devel]
    end
    if node['platform'] == 'centos' && node['platform_version'].to_i >= 6 && node['platform_version'].to_i < 7
      default['cfncluster']['kernel_devel_pkg']['name'] = "kernel-lt-devel"
    end
    if node['platform'] == 'redhat' && node['platform_version'].to_i >= 6 && node['platform_version'].to_i < 7
      default['cfncluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-releases-optional'
    end
    if node['platform'] == 'redhat' && node['platform_version'].to_i >= 7
      default['cfncluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-optional'
    end

  when 'amazon'
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate mpich-devel openmpi-devel R atlas-devel fftw-devel
                                                libffi-devel openssl-devel dkms mysql-devel libedit-devel postgresql-devel postgresql-server
                                                sendmail cmake byacc libglvnd-devel]
  end

  default['cfncluster']['ganglia']['apache_user'] = 'apache'
  default['cfncluster']['ganglia']['gmond_service'] = 'gmond'
  default['cfncluster']['ganglia']['httpd_service'] = 'httpd'
  default['cfncluster']['torque']['trqauthd_source'] = 'file:///opt/torque/contrib/init.d/trqauthd'
  default['cfncluster']['torque']['pbs_mom_source'] = 'file:///opt/torque/contrib/init.d/pbs_mom'
  default['cfncluster']['torque']['pbs_sched_source'] = 'file:///opt/torque/contrib/init.d/pbs_sched'
  default['cfncluster']['torque']['pbs_server_source'] = 'file:///opt/torque/contrib/init.d/pbs_server'

when 'debian'
  default['openssh']['server']['subsystem'] = 'sftp internal-sftp'
  default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
                                              tcl-dev automake autoconf python-parted libtool librrd-dev libapr1-dev libconfuse-dev
                                              apache2 libboost-dev libdb-dev tcsh libssl-dev libncurses5-dev libpam0g-dev libxt-dev
                                              libmotif-dev libxmu-dev libxft-dev libhwloc-dev man-db lvm2 libmpich-dev libopenmpi-dev
                                              r-base libatlas-dev libblas-dev libfftw3-dev libffi-dev libssl-dev libxml2-dev]
  if Chef::VersionConstraint.new('< 16.04').include?(node['platform_version'])
    default['cfncluster']['kernel_devel_pkg']['name'] = "linux-image-extra"
    default['cfncluster']['kernel_devel_pkg']['version'] = node['kernel']['release']
  else
    default['cfncluster']['kernel_devel_pkg']['name'] = ""
    default['cfncluster']['kernel_devel_pkg']['version'] = ""
  end
  default['cfncluster']['ganglia']['apache_user'] = 'www-data'
  default['cfncluster']['ganglia']['gmond_service'] = 'ganglia-monitor'
  default['cfncluster']['ganglia']['httpd_service'] = 'apache2'
  default['cfncluster']['torque']['trqauthd_source'] = 'file:///opt/torque/contrib/init.d/debian.trqauthd'
  default['cfncluster']['torque']['pbs_mom_source'] = 'file:///opt/torque/contrib/init.d/debian.pbs_mom'
  default['cfncluster']['torque']['pbs_sched_source'] = 'file:///opt/torque/contrib/init.d/debian.pbs_sched'
  default['cfncluster']['torque']['pbs_server_source'] = 'file:///opt/torque/contrib/init.d/debian.pbs_server'
  if Chef::VersionConstraint.new('>= 15.04').include?(node['platform_version'])
    default['nfs']['service_provider']['idmap'] = Chef::Provider::Service::Systemd
    default['nfs']['service_provider']['portmap'] = Chef::Provider::Service::Systemd
    default['nfs']['service_provider']['lock'] = Chef::Provider::Service::Systemd
    default['nfs']['service']['lock'] = 'rpc-statd'
    default['nfs']['service']['idmap'] = 'nfs-idmapd'
  end
end

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
default['cfncluster']['cfn_scheduler_slots'] = 'vcpus'
default['cfncluster']['cfn_instance_slots'] = '1'
default['cfncluster']['cfn_volume'] = nil
default['cfncluster']['cfn_volume_fs_type'] = 'ext4'
default['cfncluster']['cfn_encrypted_ephemeral'] = false
default['cfncluster']['cfn_ephemeral_dir'] = '/scratch'
default['cfncluster']['cfn_shared_dir'] = '/shared'
default['cfncluster']['cfn_node_type'] = nil
default['cfncluster']['cfn_master'] = nil
default['cfncluster']['cfn_cluster_user'] = 'ec2-user'
