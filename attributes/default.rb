# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
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
default['cfncluster']['base_dir'] = '/opt/parallelcluster'
default['cfncluster']['sources_dir'] = "#{node['cfncluster']['base_dir']}/sources"
default['cfncluster']['scripts_dir'] = "#{node['cfncluster']['base_dir']}/scripts"
default['cfncluster']['license_dir'] = "#{node['cfncluster']['base_dir']}/licenses"
# Python Version
default['cfncluster']['python-version'] = '3.6.9'
default['cfncluster']['python-version-centos6'] = '2.7.17'
# pyenv system installation root
default['cfncluster']['system_pyenv_root'] = '/usr/local/pyenv'
# Virtualenv Cookbook Name
default['cfncluster']['cookbook_virtualenv'] = 'cookbook_virtualenv'
# Virtualenv Node Name
default['cfncluster']['node_virtualenv'] = 'node_virtualenv'
# Cookbook Virtualenv Path
default['cfncluster']['cookbook_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['cookbook_virtualenv']}"
# Node Virtualenv Path
default['cfncluster']['node_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['node_virtualenv']}"
# Intel Packages
default['cfncluster']['psxe']['version'] = '2019.5'
default['cfncluster']['intelhpc']['version'] = '2018.0-1.el7'
default['cfncluster']['intelpython2']['version'] = '2019.4'
default['cfncluster']['intelpython3']['version'] = '2019.4'
# Intel MPI
default['cfncluster']['intelmpi']['url'] = "http://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16120/l_mpi_2019.6.166.tgz"
default['cfncluster']['intelmpi']['version'] = '2019.6.166'
default['cfncluster']['intelmpi']['modulefile'] = "/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}/intel64/modulefiles/mpi"
# Python packages
default['cfncluster']['cfncluster-version'] = '2.6.1'
default['cfncluster']['cfncluster-node-version'] = '2.6.1'
# URLs to software packages used during install recipes
# Gridengine software
default['cfncluster']['sge']['version'] = '8.1.9'
default['cfncluster']['sge']['url'] = 'https://arc.liv.ac.uk/downloads/SGE/releases/8.1.9/sge-8.1.9.tar.gz'
# Torque software
default['cfncluster']['torque']['version'] = '6.1.2'
default['cfncluster']['torque']['url'] = 'https://github.com/adaptivecomputing/torque/archive/6.1.2.tar.gz'
# Slurm software
default['cfncluster']['slurm']['version'] = '19.05.5'
default['cfncluster']['slurm']['url'] = 'https://download.schedmd.com/slurm/slurm-19.05.5.tar.bz2'
default['cfncluster']['slurm']['sha1'] = '055adca91e555cc124b1ecac5f3c45e66c17a8ba'
# Munge
default['cfncluster']['munge']['munge_version'] = '0.5.13'
default['cfncluster']['munge']['munge_url'] = "https://github.com/dun/munge/archive/munge-#{node['cfncluster']['munge']['munge_version']}.tar.gz"
# Ganglia
default['cfncluster']['ganglia_enabled'] = 'no'
# NVIDIA
default['cfncluster']['nvidia']['enabled'] = 'no'
# domain has dynamic DNS resolution, will resolve to a server in Tokyo when called from China
default['cfncluster']['nvidia']['driver_version'] = '440.33.01'
default['cfncluster']['nvidia']['driver_url'] = 'https://us.download.nvidia.com/tesla/440.33.01/NVIDIA-Linux-x86_64-440.33.01.run'
default['cfncluster']['nvidia']['cuda_version'] = '10.2'
default['cfncluster']['nvidia']['cuda_url'] = if node['platform'] == 'centos' && node['platform_version'].to_i < 7
                                                'http://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_rhel6.run'
                                              else
                                                'https://developer.download.nvidia.com/compute/cuda/10.2/Prod/local_installers/cuda_10.2.89_440.33.01_linux.run'
                                              end
# EFA
default['cfncluster']['efa']['installer_url'] = 'https://s3-us-west-2.amazonaws.com/aws-efa-installer/aws-efa-installer-1.8.4.tar.gz'
# ENV2 - tool to capture environment and create modulefiles
default['cfncluster']['env2']['url'] = 'https://sourceforge.net/projects/env2/files/env2/download'
# NICE DCV
default['cfncluster']['dcv']['installed'] = 'yes'
default['cfncluster']['dcv']['version'] = '2019.1-7644'
default['cfncluster']['dcv']['supported_os'] = %w[centos7 ubuntu18 amazon2]
case "#{node['platform']}#{node['platform_version'].to_i}"
when 'centos7', 'amazon2'
  default['cfncluster']['dcv']['package'] = "nice-dcv-#{node['cfncluster']['dcv']['version']}-el7"
  default['cfncluster']['dcv']['server'] = "nice-dcv-server-2019.1.7644-1.el7.x86_64.rpm" # NICE DCV server package
  default['cfncluster']['dcv']['xdcv'] = "nice-xdcv-2019.1.226-1.el7.x86_64.rpm" # required to create virtual sessions
  default['cfncluster']['dcv']['gl'] = "nice-dcv-gl-2019.1.544-1.el7.x86_64.rpm" # required to enable GPU sharing
  default['cfncluster']['dcv']['sha256sum'] = "ab50323c92b3584ac88f697fd45e68b98da0b1b334a3e1f7eef6343df3aa4d91"
when 'ubuntu18'
  default['cfncluster']['dcv']['package'] = "nice-dcv-#{node['cfncluster']['dcv']['version']}-ubuntu1804"
  default['cfncluster']['dcv']['server'] = "nice-dcv-server_2019.1.7644-1_amd64.ubuntu1804.deb" # NICE DCV server package
  default['cfncluster']['dcv']['xdcv'] = "nice-xdcv_2019.1.226-1_amd64.ubuntu1804.deb"  # required to create virtual sessions
  default['cfncluster']['dcv']['gl'] = "nice-dcv-gl_2019.1.544-1_amd64.ubuntu1804.deb"  # required to enable GPU sharing
  default['cfncluster']['dcv']['sha256sum'] = "41a0b4112c435b3a57de3ae46cfe8cdf90c33a216f488e3bfab944f034f6067f"
end
default['cfncluster']['dcv']['url'] = "https://d1uj6qtbmh3dt5.cloudfront.net/2019.1/Servers/#{node['cfncluster']['dcv']['package']}.tgz"
# DCV external authenticator configuration
default['cfncluster']['dcv']['authenticator']['user'] = "dcvextauth"
default['cfncluster']['dcv']['authenticator']['user_home'] = "/home/#{node['cfncluster']['dcv']['authenticator']['user']}"
default['cfncluster']['dcv']['authenticator']['certificate'] = "/etc/parallelcluster/ext-auth-certificate.pem"
default['cfncluster']['dcv']['authenticator']['private_key'] = "/etc/parallelcluster/ext-auth-private-key.pem"
default['cfncluster']['dcv']['authenticator']['virtualenv'] = "dcv_authenticator_virtualenv"
default['cfncluster']['dcv']['authenticator']['virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['dcv']['authenticator']['virtualenv']}"
# CloudWatch Agent
default['cfncluster']['cloudwatch']['public_key_url'] = "https://s3.amazonaws.com/amazoncloudwatch-agent/assets/amazon-cloudwatch-agent.gpg"
default['cfncluster']['cloudwatch']['public_key_local_path'] = "#{node['cfncluster']['sources_dir']}/amazon-cloudwatch-agent.gpg"

# Reboot after default_pre recipe
default['cfncluster']['default_pre_reboot'] = 'true'

# OpenSSH settings for AWS ParallelCluster instances
default['openssh']['server']['protocol'] = '2'
default['openssh']['server']['syslog_facility'] = 'AUTHPRIV'
default['openssh']['server']['permit_root_login'] = 'forced-commands-only'
default['openssh']['server']['password_authentication'] = 'no'
default['openssh']['server']['gssapi_authentication'] = 'yes'
default['openssh']['server']['gssapi_clean_up_credentials'] = 'yes'
default['openssh']['server']['subsystem'] = 'sftp /usr/libexec/openssh/sftp-server'
if node['platform'] == 'centos' && node['platform_version'].to_i < 7
  default['openssh']['server']['ciphers'] = 'aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr'
  default['openssh']['server']['m_a_cs'] = 'hmac-sha2-512,hmac-sha2-256'
else
  default['openssh']['server']['ciphers'] = 'aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com'
  default['openssh']['server']['m_a_cs'] = 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256'
end
default['openssh']['client']['gssapi_authentication'] = 'yes'
unless node['platform'] == 'centos' && node['platform_version'].to_i < 7
  default['openssh']['client']['match'] = 'exec "ssh_target_checker.sh %h"'
  # Disable StrictHostKeyChecking for target host in the cluster VPC
  default['openssh']['client']['  _strict_host_key_checking'] = 'no'
  # Do not store server key in the know hosts file to avoid scaling clashing
  # that is when an new host gets the same IP of a previously terminated host
  default['openssh']['client']['  _user_known_hosts_file'] = '/dev/null'
end

# ulimit settings
default['cfncluster']['filehandle_limit'] = 10_000
default['cfncluster']['memory_limit'] = 'unlimited'

# Platform defaults
case node['platform_family']
when 'rhel', 'amazon'

  default['cfncluster']['kernel_devel_pkg']['name'] = "kernel-devel"
  default['cfncluster']['kernel_devel_pkg']['version'] = node['kernel']['release'].chomp('.x86_64')

  # Modulefile Directory
  default['cfncluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"

  case node['platform']
  when 'centos', 'redhat', 'scientific' # ~FC024
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate mpich-devel openmpi-devel R atlas-devel
                                                blas-devel fftw-devel libffi-devel openssl-devel dkms mysql-devel libedit-devel
                                                libical-devel postgresql-devel postgresql-server sendmail mdadm python python-pip
                                                libgcrypt-devel]

    # Lustre Drivers for Centos 6
    default['cfncluster']['lustre']['version'] = '2.10.6'
    default['cfncluster']['lustre']['kmod_url'] = 'https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el6/client/RPMS/x86_64/kmod-lustre-client-2.10.6-1.el6.x86_64.rpm'
    default['cfncluster']['lustre']['client_url'] = 'https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el6/client/RPMS/x86_64/lustre-client-2.10.6-1.el6.x86_64.rpm'

    if node['platform_version'].to_i >= 7
      default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                  libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                                  httpd boost-devel redhat-lsb mlocate lvm2 mpich-devel R atlas-devel
                                                  blas-devel fftw-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                                  libical-devel postgresql-devel postgresql-server sendmail libxml2-devel libglvnd-devel mdadm python python-pip
                                                  libssh2-devel libgcrypt-devel]
      if node['platform_version'].split('.')[1] >= '7'
        # Lustre Client for Centos >= 7.7
        default['cfncluster']['lustre']['public_key'] = 'https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc'
        default['cfncluster']['lustre']['base_url'] = "https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.#{node['platform_version'].split('.')[1]}/x86_64/"
      elsif node['platform_version'].split('.')[1] == '6'
        # Lustre Drivers for Centos 7.6
        default['cfncluster']['lustre']['version'] = '2.10.6'
        default['cfncluster']['lustre']['kmod_url'] = 'https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.6-1.el7.x86_64.rpm'
        default['cfncluster']['lustre']['client_url'] = 'https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/lustre-client-2.10.6-1.el7.x86_64.rpm'
      elsif node['platform_version'].split('.')[1] == '5'
        # Lustre Drivers for Centos 7.5
        default['cfncluster']['lustre']['version'] = '2.10.5'
        default['cfncluster']['lustre']['kmod_url'] = 'https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm'
        default['cfncluster']['lustre']['client_url'] = 'https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm'
      end
    end
    default['cfncluster']['kernel_devel_pkg']['name'] = "kernel-lt-devel" if node['platform'] == 'centos' && node['platform_version'].to_i >= 6 && node['platform_version'].to_i < 7
    default['cfncluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-releases-optional' if node['platform'] == 'redhat' && node['platform_version'].to_i >= 6 && node['platform_version'].to_i < 7
    default['cfncluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-optional' if node['platform'] == 'redhat' && node['platform_version'].to_i >= 7

  when 'amazon'
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate mpich-devel R atlas-devel fftw-devel
                                                libffi-devel dkms mysql-devel libedit-devel postgresql-devel postgresql-server
                                                sendmail cmake byacc libglvnd-devel mdadm libgcrypt-devel]
    if node['platform_version'].to_i == 2
      # mpich-devel not available on alinux
      default['cfncluster']['base_packages'].delete('mpich-devel')
      # Swap out some packages for their alinux2 equivalents
      [%w[db4-devel libdb-devel], %w[redhat-lsb system-lsb]].each do |al1, al2equiv|
        default['cfncluster']['base_packages'].delete(al1)
        default['cfncluster']['base_packages'].push(al2equiv)
      end
      # Add additional base packages, most of which would be installed as part of `yum groupinstall development`
      default['cfncluster']['base_packages'].concat(%w[libxml2-devel perl-devel dpkg-dev tar gzip bison flex gcc gcc-c++ patch
                                                       rpm-build rpm-sign system-rpm-config cscope ctags diffstat doxygen elfutils
                                                       gcc-gfortran git indent intltool patchutils rcs subversion swig systemtap curl
                                                       jq wget python-pip])
      # Download from debian repo (https://packages.debian.org/source/buster/gridengine)
      # because it contains fixes for known build issues
      default['cfncluster']['sge']['url'] = 'http://deb.debian.org/debian/pool/main/g/gridengine/gridengine_8.1.9+dfsg.orig.tar.gz'
      default['cfncluster']['sge']['version'] = '8.1.9+dfsg-9'
    end
  end

  default['cfncluster']['ganglia']['gmond_service'] = 'gmond'
  default['cfncluster']['ganglia']['httpd_service'] = 'httpd'
  default['cfncluster']['chrony']['service'] = "chronyd"
  default['cfncluster']['chrony']['conf'] = "/etc/chrony.conf"
  default['cfncluster']['torque']['trqauthd_source'] = 'file:///opt/torque/contrib/init.d/trqauthd'
  default['cfncluster']['torque']['pbs_mom_source'] = 'file:///opt/torque/contrib/init.d/pbs_mom'
  default['cfncluster']['torque']['pbs_sched_source'] = 'file:///opt/torque/contrib/init.d/pbs_sched'
  default['cfncluster']['torque']['pbs_server_source'] = 'file:///opt/torque/contrib/init.d/pbs_server'

when 'debian'
  default['openssh']['server']['subsystem'] = 'sftp internal-sftp'
  default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
                                              tcl-dev automake autoconf python-parted libtool librrd-dev libapr1-dev libconfuse-dev
                                              apache2 libboost-dev libdb-dev tcsh libssl-dev libncurses5-dev libpam0g-dev libxt-dev
                                              libmotif-dev libxmu-dev libxft-dev libhwloc-dev man-db lvm2 libmpich-dev python python-pip
                                              r-base libatlas-dev libblas-dev libfftw3-dev libffi-dev libssl-dev libxml2-dev mdadm
                                              libgcrypt20-dev libmysqlclient-dev]
  if node['platform_version'] == '18.04'
    default['cfncluster']['base_packages'].delete('libatlas-dev')
    default['cfncluster']['base_packages'].push('libatlas-base-dev', 'libssl-dev', 'libglvnd-dev')
    default['cfncluster']['sge']['version'] = '8.1.9+dfsg-9build1'
  end

  default['cfncluster']['lustre']['public_key'] = 'https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc'
  default['cfncluster']['lustre']['repository_uri'] = 'https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu'
  # Modulefile Directory
  default['cfncluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"
  default['cfncluster']['kernel_generic_pkg'] = "linux-generic"
  default['cfncluster']['ganglia']['gmond_service'] = 'ganglia-monitor'
  default['cfncluster']['ganglia']['httpd_service'] = 'apache2'
  default['cfncluster']['chrony']['service'] = "chrony"
  default['cfncluster']['chrony']['conf'] = "/etc/chrony/chrony.conf"
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

# ParallelCluster internal variables (also in /etc/parallelcluster/cfnconfig)
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
default['cfncluster']['cfn_efs_shared_dir'] = 'NONE'
default['cfncluster']['cfn_efs'] = nil
default['cfncluster']['cfn_master'] = nil
default['cfncluster']['cfn_cluster_user'] = 'ec2-user'
default['cfncluster']['cfn_fsx_options'] = 'NONE'
default['cfncluster']['cfn_fsx_fs_id'] = nil
default['cfncluster']['custom_node_package'] = nil
default['cfncluster']['custom_awsbatchcli_package'] = nil
default['cfncluster']['cfn_raid_parameters'] = 'NONE'
default['cfncluster']['cfn_raid_vol_ids'] = nil
default['cfncluster']['skip_install_recipes'] = 'yes'
