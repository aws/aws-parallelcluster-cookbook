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
default['cfncluster']['configs_dir'] = "#{node['cfncluster']['base_dir']}/configs"

# Cluster config
default['cfncluster']['cluster_s3_bucket'] = nil
default['cfncluster']['cluster_config_s3_key'] = nil
default['cfncluster']['cluster_config_version'] = nil
default['cfncluster']['cluster_config_path'] = "#{node['cfncluster']['configs_dir']}/cluster_config.json"

# Python Version
default['cfncluster']['python-version'] = '3.6.9'
# plcuster-specific pyenv system installation root
default['cfncluster']['system_pyenv_root'] = "#{node['cfncluster']['base_dir']}/pyenv"
# Virtualenv Cookbook Name
default['cfncluster']['cookbook_virtualenv'] = 'cookbook_virtualenv'
# Virtualenv Node Name
default['cfncluster']['node_virtualenv'] = 'node_virtualenv'
# Cookbook Virtualenv Path
default['cfncluster']['cookbook_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['cookbook_virtualenv']}"
# Node Virtualenv Path
default['cfncluster']['node_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['node_virtualenv']}"

# Intel Packages
default['cfncluster']['psxe']['version'] = '2020.4'
default['cfncluster']['intelhpc']['platform_name'] = value_for_platform(
  'centos' => {
    '~>8' => 'el8',
    '~>7' => 'el7'
  }
)
default['cfncluster']['intelhpc']['version'] = "2018.0-*.#{node['cfncluster']['intelhpc']['platform_name']}"
default['cfncluster']['intelpython2']['version'] = '2019.4'
default['cfncluster']['intelpython3']['version'] = '2020.2'

# Intel MPI
default['cfncluster']['intelmpi']['url'] = "https://registrationcenter-download.intel.com/akdlm/irc_nas/tec/16814/l_mpi_2019.8.254.tgz"
default['cfncluster']['intelmpi']['version'] = '2019.8.254'
default['cfncluster']['intelmpi']['modulefile'] = "/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}/intel64/modulefiles/mpi"

# Python packages
default['cfncluster']['cfncluster-version'] = '2.9.1'
default['cfncluster']['cfncluster-cookbook-version'] = '2.9.1'
default['cfncluster']['cfncluster-node-version'] = '2.9.1'

# URLs to software packages used during install recipes
# Gridengine software
default['cfncluster']['sge']['version'] = '8.1.9'
default['cfncluster']['sge']['url'] = 'https://arc.liv.ac.uk/downloads/SGE/releases/8.1.9/sge-8.1.9.tar.gz'
# Torque software
default['cfncluster']['torque']['version'] = '6.1.2'
default['cfncluster']['torque']['url'] = 'https://github.com/adaptivecomputing/torque/archive/6.1.2.tar.gz'
# Slurm software
default['cfncluster']['slurm_plugin_dir'] = '/etc/parallelcluster/slurm_plugin'
default['cfncluster']['slurm']['version'] = '20.02.4'
default['cfncluster']['slurm']['url'] = 'https://download.schedmd.com/slurm/slurm-20.02.4.tar.bz2'
default['cfncluster']['slurm']['sha1'] = '294de3a2e1410945eb516c40eff5f92087501893'
# PMIx software
default['cfncluster']['pmix']['version'] = '3.1.5'
default['cfncluster']['pmix']['url'] = "https://github.com/openpmix/openpmix/releases/download/v#{node['cfncluster']['pmix']['version']}/pmix-#{node['cfncluster']['pmix']['version']}.tar.gz"
default['cfncluster']['pmix']['sha1'] = '36bfb962858879cefa7a04a633c1b6984cea03ec'
# Munge
default['cfncluster']['munge']['munge_version'] = '0.5.14'
default['cfncluster']['munge']['munge_url'] = "https://github.com/dun/munge/archive/munge-#{node['cfncluster']['munge']['munge_version']}.tar.gz"
# Munge key
default['cfncluster']['munge']['munge_key'] = 'YflQEFLjoxsmEK5vQyKklkLKJ#LkjLKDJF@*(#)ajLKQ@hLKN#()FSU(#@KLJH$@HKSASG)*DUJJDksdN'

# Ganglia
default['cfncluster']['ganglia_enabled'] = 'no'

# NVIDIA
default['cfncluster']['nvidia']['enabled'] = 'no'
default['cfncluster']['nvidia']['driver_version'] = '450.51.05'
default['cfncluster']['nvidia']['driver_url'] = 'https://us.download.nvidia.com/tesla/450.51.05/NVIDIA-Linux-x86_64-450.51.05.run'
default['cfncluster']['nvidia']['cuda_version'] = '11.0'
default['cfncluster']['nvidia']['cuda_url'] = 'https://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run'

# EFA
default['cfncluster']['efa']['installer_version'] = '1.10.0'
default['cfncluster']['efa']['installer_url'] = "https://efa-installer.amazonaws.com/aws-efa-installer-#{node['cfncluster']['efa']['installer_version']}.tar.gz"

# NICE DCV
default['cfncluster']['dcv_port'] = 8443
default['cfncluster']['dcv']['installed'] = 'yes'
default['cfncluster']['dcv']['version'] = '2020.1-9012'
if arm_instance?
  default['cfncluster']['dcv']['supported_os'] = %w[centos8 ubuntu18 amazon2]
  default['cfncluster']['dcv']['url_architecture_id'] = 'aarch64'
  default['cfncluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>8' => "eca626c10a6fe8b8770b1809555e6c1747a8ab7b6991e25e370d8d0c19902f4e",
      '~>7' => "d590d81360b0e96652cd1ef3a74fff5cb9381f57ff55685a8ddde48d494968e4"
    },
    'amazon' => { '2' => "d590d81360b0e96652cd1ef3a74fff5cb9381f57ff55685a8ddde48d494968e4" },
    'ubuntu' => { '18.04' => "0cd0512d57808cee0c48d0817a515825f9c512cb9d70e5672fecbb7450b729b3" }
  )
else
  default['cfncluster']['dcv']['supported_os'] = %w[centos8 centos7 ubuntu18 amazon2]
  default['cfncluster']['dcv']['url_architecture_id'] = 'x86_64'
  default['cfncluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>8' => "ecaed9e711630c26b25b8ea2a21db4bf93795cb7d6186a6a1dde8a7a9f37d54a",
      '~>7' => "c36020cce52ba371a796c041352db6c5d6d55d35acbbfbadafd834e1265aa5bf"
    },
    'amazon' => { '2' => "c36020cce52ba371a796c041352db6c5d6d55d35acbbfbadafd834e1265aa5bf" },
    'ubuntu' => { '18.04' => "7569c95465743b512f1ab191e58ea09777353b401c1ec130ee8ea344e00f8900" }
  )
end
if "#{node['platform']}#{node['platform_version'].to_i}" == 'ubuntu18'
  # Unlike the other supported OSs, the DCV package names for Ubuntu 18.04 use different architecture abbreviations than those used in the download URLs.
  default['cfncluster']['dcv']['package_architecture_id'] = arm_instance? ? 'arm64' : 'amd64'
end
default['cfncluster']['dcv']['package'] = value_for_platform(
  'centos' => {
    '~>8' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-el8-#{node['cfncluster']['dcv']['url_architecture_id']}",
    '~>7' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-el7-#{node['cfncluster']['dcv']['url_architecture_id']}"
  },
  'amazon' => { '2' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-el7-#{node['cfncluster']['dcv']['url_architecture_id']}" },
  'ubuntu' => { '18.04' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-ubuntu1804-#{node['cfncluster']['dcv']['url_architecture_id']}" }
)
default['cfncluster']['dcv']['server'] = value_for_platform( # NICE DCV server package
  'centos' => {
    '~>8' => "nice-dcv-server-2020.1.9012-1.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-dcv-server-2020.1.9012-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-server-2020.1.9012-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => { '18.04' => "nice-dcv-server_2020.1.9012-1_#{node['cfncluster']['dcv']['package_architecture_id']}.ubuntu1804.deb" }
)
default['cfncluster']['dcv']['xdcv'] = value_for_platform( # required to create virtual sessions
  'centos' => {
    '~>8' => "nice-xdcv-2020.1.338-1.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-xdcv-2020.1.338-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-xdcv-2020.1.338-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => { '18.04' => "nice-xdcv_2020.1.338-1_#{node['cfncluster']['dcv']['package_architecture_id']}.ubuntu1804.deb" }
)
default['cfncluster']['dcv']['gl'] = value_for_platform( # required to enable GPU sharing
  'centos' => {
    '~>8' => "nice-dcv-gl-2020.1.840-1.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-dcv-gl-2020.1.840-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-gl-2020.1.840-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => { '18.04' => "nice-dcv-gl_2020.1.840-1_#{node['cfncluster']['dcv']['package_architecture_id']}.ubuntu1804.deb" }
)
default['cfncluster']['dcv']['url'] = "https://d1uj6qtbmh3dt5.cloudfront.net/2020.1/Servers/#{node['cfncluster']['dcv']['package']}.tgz"
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
default['openssh']['server']['ciphers'] = 'aes128-cbc,aes192-cbc,aes256-cbc,aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com'
default['openssh']['server']['m_a_cs'] = 'hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256'
default['openssh']['client']['gssapi_authentication'] = 'yes'
default['openssh']['client']['match'] = 'exec "ssh_target_checker.sh %h"'
# Disable StrictHostKeyChecking for target host in the cluster VPC
default['openssh']['client']['  _strict_host_key_checking'] = 'no'
# Do not store server key in the know hosts file to avoid scaling clashing
# that is when an new host gets the same IP of a previously terminated host
default['openssh']['client']['  _user_known_hosts_file'] = '/dev/null'

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
  # MODULESHOME
  default['cfncluster']['moduleshome'] = "/usr/share/Modules"

  case node['platform']
  when 'centos', 'redhat', 'scientific' # ~FC024
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate lvm2 mpich-devel R atlas-devel
                                                blas-devel fftw-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                                libical-devel postgresql-devel postgresql-server sendmail libxml2-devel libglvnd-devel
                                                mdadm python python-pip libssh2-devel libgcrypt-devel libevent-devel glibc-static bind-utils]
    if node['platform_version'].to_i >= 8
      # Install python3 instead of unversioned python
      default['cfncluster']['base_packages'].delete('python')
      default['cfncluster']['base_packages'].delete('python-pip')
      # iptables used in configure-pat.sh
      # nvme-cli used to retrieve info about EBS volumes in parallelcluster-ebsnvme-id
      # gdisk required for FSx
      # environment-modules required for IntelMPI
      # libtirpc and libtirpc-devel required for SGE
      default['cfncluster']['base_packages'].push(%w[python3 python3-pip iptables nvme-cli gdisk environment-modules libtirpc libtirpc-devel])
    end

    default['cfncluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-optional'

  when 'amazon'
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel db4-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate mpich-devel R atlas-devel fftw-devel
                                                libffi-devel dkms mysql-devel libedit-devel postgresql-devel postgresql-server
                                                sendmail cmake byacc libglvnd-devel mdadm libgcrypt-devel libevent-devel
                                                glibc-static]
    if node['platform_version'].to_i == 2
      # mpich-devel not available on alinux
      default['cfncluster']['base_packages'].delete('mpich-devel')
      # Install R via amazon linux extras instead
      default['cfncluster']['base_packages'].delete('R')
      default['cfncluster']['alinux_extras'] = ['R3.4']
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
      default['cfncluster']['sge']['url'] = 'https://deb.debian.org/debian/pool/main/g/gridengine/gridengine_8.1.9+dfsg.orig.tar.gz'
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
                                              libgcrypt20-dev libmysqlclient-dev libevent-dev]
  if node['platform_version'] == '18.04'
    default['cfncluster']['base_packages'].delete('libatlas-dev')
    default['cfncluster']['base_packages'].push('libatlas-base-dev', 'libssl-dev', 'libglvnd-dev')
    default['cfncluster']['sge']['version'] = '8.1.9+dfsg-9build1'
  end

  # Modulefile Directory
  default['cfncluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"
  # MODULESHOME
  default['cfncluster']['moduleshome'] = "/usr/share/modules"
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

# Lustre defaults (for CentOS >=7.7 and Ubuntu)
default['cfncluster']['lustre']['public_key'] = value_for_platform(
  'centos' => { '>=7.7' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc" },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc" }
)
default['cfncluster']['lustre']['base_url'] = value_for_platform(
  'centos' => {
    # node['kernel']['machine'] contains the architecture: 'x86_64' or 'aarch64'
    '>=8' => "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8/#{node['kernel']['machine']}/",
    'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.#{find_rhel7_kernel_minor_version}/x86_64/"
  },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu" }
)
# Lustre defaults (for CentOS 7.6 and 7.5 only)
default['cfncluster']['lustre']['version'] = value_for_platform(
  'centos' => {
    '7.6' => "2.10.6",
    '7.5' => "2.10.5"
  }
)
default['cfncluster']['lustre']['kmod_url'] = value_for_platform(
  'centos' => {
    '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.6-1.el7.x86_64.rpm",
    '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm"
  }
)
default['cfncluster']['lustre']['client_url'] = value_for_platform(
  'centos' => {
    '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/lustre-client-2.10.6-1.el7.x86_64.rpm",
    '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm"
  }
)

# ParallelCluster internal variables (also in /etc/parallelcluster/cfnconfig)
default['cfncluster']['cfn_region'] = 'us-east-1'
default['cfncluster']['stack_name'] = nil
default['cfncluster']['cfn_sqs_queue'] = nil
default['cfncluster']['cfn_ddb_table'] = nil
default['cfncluster']['cfn_node_type'] = nil
default['cfncluster']['cfn_preinstall'] = 'NONE'
default['cfncluster']['cfn_preinstall_args'] = 'NONE'
default['cfncluster']['cfn_proxy'] = 'NONE'
default['cfncluster']['cfn_postinstall'] = 'NONE'
default['cfncluster']['cfn_postinstall_args'] = 'NONE'
default['cfncluster']['cfn_scheduler'] = 'sge'
default['cfncluster']['cfn_scheduler_slots'] = 'vcpus'
default['cfncluster']['cfn_disable_hyperthreading_manually'] = 'false'
default['cfncluster']['cfn_instance_slots'] = '1'
default['cfncluster']['cfn_volume'] = nil
default['cfncluster']['cfn_volume_fs_type'] = 'ext4'
default['cfncluster']['cfn_encrypted_ephemeral'] = false
default['cfncluster']['cfn_ephemeral_dir'] = '/scratch'
default['cfncluster']['cfn_shared_dir'] = '/shared'
default['cfncluster']['cfn_efs_shared_dir'] = 'NONE'
default['cfncluster']['cfn_efs'] = nil
default['cfncluster']['cfn_master'] = nil
default['cfncluster']['cfn_master_private_ip'] = nil
default['cfncluster']['cfn_cluster_user'] = 'ec2-user'
default['cfncluster']['cfn_fsx_options'] = 'NONE'
default['cfncluster']['cfn_fsx_fs_id'] = nil
default['cfncluster']['custom_node_package'] = nil
default['cfncluster']['custom_awsbatchcli_package'] = nil
default['cfncluster']['cfn_raid_parameters'] = 'NONE'
default['cfncluster']['cfn_raid_vol_ids'] = nil
default['cfncluster']['cfn_dns_domain'] = nil
default['cfncluster']['use_private_hostname'] = 'false'
default['cfncluster']['skip_install_recipes'] = 'yes'
default['cfncluster']['scheduler_queue_name'] = nil

# AWS domain
default['cfncluster']['aws_domain'] = aws_domain
