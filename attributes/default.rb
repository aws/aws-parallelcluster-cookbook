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
default['cfncluster']['psxe']['version'] = '2020.4-17'
default['cfncluster']['psxe']['noarch_packages'] = %w[intel-tbb-common-runtime intel-mkl-common-runtime intel-psxe-common-runtime
                                                      intel-ipp-common-runtime intel-ifort-common-runtime intel-icc-common-runtime
                                                      intel-daal-common-runtime intel-comp-common-runtime]
default['cfncluster']['psxe']['archful_packages']['i486'] = %w[intel-tbb-runtime intel-tbb-libs-runtime intel-comp-runtime
                                                               intel-daal-runtime intel-icc-runtime intel-ifort-runtime
                                                               intel-ipp-runtime intel-mkl-runtime intel-openmp-runtime]
default['cfncluster']['psxe']['archful_packages']['x86_64'] = node['cfncluster']['psxe']['archful_packages']['i486'] + %w[intel-mpi-runtime]
default['cfncluster']['intelhpc']['platform_name'] = value_for_platform(
  'centos' => {
    '~>8' => 'el8',
    '~>7' => 'el7'
  }
)
default['cfncluster']['intelhpc']['packages'] = %w[intel-hpc-platform-core-intel-runtime-advisory intel-hpc-platform-compat-hpc-advisory
                                                   intel-hpc-platform-core intel-hpc-platform-core-advisory intel-hpc-platform-hpc-cluster
                                                   intel-hpc-platform-compat-hpc intel-hpc-platform-core-intel-runtime]
default['cfncluster']['intelhpc']['version'] = '2018.0-7'
default['cfncluster']['intelpython2']['version'] = '2019.4-088'
default['cfncluster']['intelpython3']['version'] = '2020.2-902'

# Intel MPI
default['cfncluster']['intelmpi']['version'] = '2019.8.254'
default['cfncluster']['intelmpi']['modulefile'] = "/opt/intel/impi/#{node['cfncluster']['intelmpi']['version']}/intel64/modulefiles/mpi"
default['cfncluster']['intelmpi']['kitchen_test_string'] = 'Version 2019 Update 8'

# Arm Performance Library
default['cfncluster']['armpl']['version'] = '20.2.1'
default['cfncluster']['armpl']['gcc']['major_minor_version'] = '9.3'
default['cfncluster']['armpl']['gcc']['patch_version'] = '0'
default['cfncluster']['armpl']['gcc']['url'] = "https://ftp.gnu.org/gnu/gcc/gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']}/gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']}.tar.gz"
default['cfncluster']['armpl']['platform'] = value_for_platform(
    'centos' => { '~>8' => 'RHEL-8' },
    'amazon' => { '2' => 'RHEL-8' },
    'ubuntu' => { '18.04' => 'Ubuntu-16.04' }
)
default['cfncluster']['armpl']['url'] = value_for_platform(
    'centos' => { '~>8' => "archives/armpl/RHEL-8/arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}_gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.tar" },
    'amazon' => { '2' => "archives/armpl/RHEL-8/arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}_gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.tar" },
    'ubuntu' => { '18.04' => "archives/armpl/Ubuntu-16.04/arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}_gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.tar" }
)

# Python packages
default['cfncluster']['cfncluster-version'] = '2.10.1'
default['cfncluster']['cfncluster-cookbook-version'] = '2.10.1'
default['cfncluster']['cfncluster-node-version'] = '2.10.1'

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
default['cfncluster']['nvidia']['driver_version'] = '450.80.02'
default['cfncluster']['nvidia']['driver_url'] = 'https://us.download.nvidia.com/tesla/450.80.02/NVIDIA-Linux-x86_64-450.80.02.run'
default['cfncluster']['nvidia']['cuda_version'] = '11.0'
default['cfncluster']['nvidia']['cuda_url'] = 'https://developer.download.nvidia.com/compute/cuda/11.0.2/local_installers/cuda_11.0.2_450.51.05_linux.run'

# NVIDIA fabric-manager
default['cfncluster']['nvidia']['fabricmanager']['package'] = "nvidia-fabricmanager-450"
default['cfncluster']['nvidia']['fabricmanager']['repository_key'] = "7fa2af80.pub"
default['cfncluster']['nvidia']['fabricmanager']['version'] = value_for_platform(
  'default' => node['cfncluster']['nvidia']['driver_version'],
  # with apt a star is needed to match the package version
  'ubuntu' => { 'default' => "#{node['cfncluster']['nvidia']['driver_version']}*" }
)
default['cfncluster']['nvidia']['fabricmanager']['repository_uri'] = value_for_platform(
  'default' => "https://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64",
  'centos' => {
    '~>8' => "https://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64",
  },
  'ubuntu' => { 'default' => "https://developer.download.nvidia.com/compute/cuda/repos/#{node['cfncluster']['cfn_base_os']}/x86_64" }
)

# EFA
default['cfncluster']['efa']['installer_version'] = '1.11.0'
default['cfncluster']['efa']['installer_url'] = "https://efa-installer.amazonaws.com/aws-efa-installer-#{node['cfncluster']['efa']['installer_version']}.tar.gz"
default['cfncluster']['enable_efa_gdr'] = "no"

# NICE DCV
default['cfncluster']['dcv_port'] = 8443
default['cfncluster']['dcv']['installed'] = 'yes'
default['cfncluster']['dcv']['version'] = '2020.2-9662'
if arm_instance?
  default['cfncluster']['dcv']['supported_os'] = %w[centos8 ubuntu18 amazon2]
  default['cfncluster']['dcv']['url_architecture_id'] = 'aarch64'
  default['cfncluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>8' => "b19d4f7472f22722942014c45470fd24423f3de030467e5027d93bbb45b5c582",
      '~>7' => "dae8bc96e7d5defe7b54a50f91b3ea4c7a9371fd68349ba744bab7ad82fdd66b"
    },
    'amazon' => { '2' => "dae8bc96e7d5defe7b54a50f91b3ea4c7a9371fd68349ba744bab7ad82fdd66b" },
    'ubuntu' => { '18.04' => "e435110902065df8cba95f31990b735aaf8d46cbad64607168891f8af96ebf84" }
  )
else
  default['cfncluster']['dcv']['supported_os'] = %w[centos8 centos7 ubuntu18 amazon2]
  default['cfncluster']['dcv']['url_architecture_id'] = 'x86_64'
  default['cfncluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>8' => "b39b923110f8f02d1a5d4b512abc5ecac5a34be73af3cd0bb4dd73943df9660f",
      '~>7' => "4a473225ec9afa8357e00a0f5b942373b952e612ce83a49c76ddc864cb2e00f0"
    },
    'amazon' => { '2' => "4a473225ec9afa8357e00a0f5b942373b952e612ce83a49c76ddc864cb2e00f0" },
    'ubuntu' => { '18.04' => "5328ff75251eddfbf40be6f0073afe9a6919be6004372f1a52391ba8490d71cb" }
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
    '~>8' => "nice-dcv-server-2020.2.9662-1.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-dcv-server-2020.2.9662-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-server-2020.2.9662-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => { '18.04' => "nice-dcv-server_2020.2.9662-1_#{node['cfncluster']['dcv']['package_architecture_id']}.ubuntu1804.deb" }
)
default['cfncluster']['dcv']['xdcv'] = value_for_platform( # required to create virtual sessions
  'centos' => {
    '~>8' => "nice-xdcv-2020.2.359-1.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-xdcv-2020.2.359-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-xdcv-2020.2.359-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => { '18.04' => "nice-xdcv_2020.2.359-1_#{node['cfncluster']['dcv']['package_architecture_id']}.ubuntu1804.deb" }
)
default['cfncluster']['dcv']['gl'] = value_for_platform( # required to enable GPU sharing
  'centos' => {
    '~>8' => "nice-dcv-gl-2020.2.881-1.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-dcv-gl-2020.2.881-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-gl-2020.2.881-1.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => { '18.04' => "nice-dcv-gl_2020.2.881-1_#{node['cfncluster']['dcv']['package_architecture_id']}.ubuntu1804.deb" }
)
default['cfncluster']['dcv']['url'] = "https://d1uj6qtbmh3dt5.cloudfront.net/2020.2/Servers/#{node['cfncluster']['dcv']['package']}.tgz"
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
                                                mdadm python python-pip libssh2-devel libgcrypt-devel libevent-devel glibc-static bind-utils
                                                iproute NetworkManager-config-routing-rules]
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
                                                glibc-static iproute]
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
                                                       jq wget python-pip NetworkManager-config-routing-rules libibverbs-utils librdmacm-utils])
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
                                              libgcrypt20-dev libmysqlclient-dev libevent-dev iproute2]
  if node['platform_version'] == '18.04'
    default['cfncluster']['base_packages'].delete('libatlas-dev')
    default['cfncluster']['base_packages'].push('libatlas-base-dev', 'libssl-dev', 'libglvnd-dev')
    default['cfncluster']['sge']['url'] = 'https://deb.debian.org/debian/pool/main/g/gridengine/gridengine_8.1.9+dfsg.orig.tar.gz'
    default['cfncluster']['sge']['version'] = '8.1.9+dfsg-9'
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
# Lustre repo string is built following the official doc
# https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html
default['cfncluster']['lustre']['base_url'] = value_for_platform(
  'centos' => {
    # node['kernel']['machine'] contains the architecture: 'x86_64' or 'aarch64'
    '>=8' => "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8.#{find_rhel_minor_version}/#{node['kernel']['machine']}/",
    'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/el/7.#{find_rhel_minor_version}/x86_64/"
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
