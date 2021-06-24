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
default['cfncluster']['python-version'] = '3.7.10'
# plcuster-specific pyenv system installation root
default['cfncluster']['system_pyenv_root'] = "#{node['cfncluster']['base_dir']}/pyenv"
# Virtualenv Cookbook Name
default['cfncluster']['cookbook_virtualenv'] = 'cookbook_virtualenv'
# Virtualenv Node Name
default['cfncluster']['node_virtualenv'] = 'node_virtualenv'
# Virtualenv AWSBatch Name
default['cfncluster']['awsbatch_virtualenv'] = 'awsbatch_virtualenv'
# Cookbook Virtualenv Path
default['cfncluster']['cookbook_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['cookbook_virtualenv']}"
# Node Virtualenv Path
default['cfncluster']['node_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['node_virtualenv']}"
# AWSBatch Virtualenv Path
default['cfncluster']['awsbatch_virtualenv_path'] = "#{node['cfncluster']['system_pyenv_root']}/versions/#{node['cfncluster']['python-version']}/envs/#{node['cfncluster']['awsbatch_virtualenv']}"

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
default['cfncluster']['armpl']['major_minor_version'] = '21.0'
default['cfncluster']['armpl']['patch_version'] = '0'
default['cfncluster']['armpl']['version'] = "#{node['cfncluster']['armpl']['major_minor_version']}.#{node['cfncluster']['armpl']['patch_version']}"

default['cfncluster']['armpl']['gcc']['major_minor_version'] = '9.3'
default['cfncluster']['armpl']['gcc']['patch_version'] = '0'
default['cfncluster']['armpl']['gcc']['url'] = [
  'https://ftp.gnu.org/gnu/gcc',
  "gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']}",
  "gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']}.tar.gz"
].join('/')
default['cfncluster']['armpl']['platform'] = value_for_platform(
  'centos' => {
    '~>7' => 'RHEL-7',
    '~>8' => 'RHEL-8'
  },
  'amazon' => { '2' => 'RHEL-8' },
  'ubuntu' => {
    '18.04' => 'Ubuntu-18.04',
    '20.04' => 'Ubuntu-20.04'
  }
)
default['cfncluster']['armpl']['url'] = [
  'archives/armpl',
  node['cfncluster']['armpl']['platform'],
  "arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}_gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.tar"
].join('/')

# Python packages
default['cfncluster']['cfncluster-version'] = '2.11.0'
default['cfncluster']['cfncluster-cookbook-version'] = '2.11.0'
default['cfncluster']['cfncluster-node-version'] = '2.11.0'

# URLs to software packages used during install recipes
# Gridengine software
default['cfncluster']['sge']['version'] = '8.1.9'
default['cfncluster']['sge']['url'] = 'https://arc.liv.ac.uk/downloads/SGE/releases/8.1.9/sge-8.1.9.tar.gz'
# Torque software
default['cfncluster']['torque']['version'] = '6.1.2'
default['cfncluster']['torque']['url'] = 'https://github.com/adaptivecomputing/torque/archive/6.1.2.tar.gz'
# Slurm software
default['cfncluster']['slurm_plugin_dir'] = '/etc/parallelcluster/slurm_plugin'
default['cfncluster']['slurm']['version'] = '20-11-7-1'
default['cfncluster']['slurm']['url'] = "https://github.com/SchedMD/slurm/archive/slurm-#{node['cfncluster']['slurm']['version']}.tar.gz"
default['cfncluster']['slurm']['sha1'] = 'ce927fbf2f7d5f908ed87c5d521abc696b9a2508'
# PMIx software
default['cfncluster']['pmix']['version'] = '3.1.5'
default['cfncluster']['pmix']['url'] = "https://github.com/openpmix/openpmix/releases/download/v#{node['cfncluster']['pmix']['version']}/pmix-#{node['cfncluster']['pmix']['version']}.tar.gz"
default['cfncluster']['pmix']['sha1'] = '36bfb962858879cefa7a04a633c1b6984cea03ec'
# Munge
default['cfncluster']['munge']['munge_version'] = '0.5.14'
default['cfncluster']['munge']['munge_url'] = "https://github.com/dun/munge/archive/munge-#{node['cfncluster']['munge']['munge_version']}.tar.gz"

# Ganglia
default['cfncluster']['ganglia_enabled'] = 'no'

# NVIDIA
default['cfncluster']['nvidia']['enabled'] = 'no'
default['cfncluster']['nvidia']['driver_version'] = '460.73.01'
default['cfncluster']['nvidia']['driver_url'] = 'https://us.download.nvidia.com/tesla/460.73.01/NVIDIA-Linux-x86_64-460.73.01.run'
default['cfncluster']['nvidia']['cuda_version'] = '11.3'
default['cfncluster']['nvidia']['cuda_url'] = 'https://developer.download.nvidia.com/compute/cuda/11.3.0/local_installers/cuda_11.3.0_465.19.01_linux.run'

# NVIDIA fabric-manager
default['cfncluster']['nvidia']['fabricmanager']['package'] = "nvidia-fabricmanager-460"
default['cfncluster']['nvidia']['fabricmanager']['repository_key'] = "7fa2af80.pub"
default['cfncluster']['nvidia']['fabricmanager']['version'] = value_for_platform(
  'default' => node['cfncluster']['nvidia']['driver_version'],
  # with apt a star is needed to match the package version
  'ubuntu' => { 'default' => "#{node['cfncluster']['nvidia']['driver_version']}*" }
)
default['cfncluster']['nvidia']['fabricmanager']['repository_uri'] = value_for_platform(
  'default' => "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel7/x86_64",
  'centos' => {
    '~>8' => "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel8/x86_64"
  },
  'ubuntu' => { 'default' => "https://developer.download.nvidia._domain_/compute/cuda/repos/#{node['cfncluster']['cfn_base_os']}/x86_64" }
)

# EFA
default['cfncluster']['efa']['installer_version'] = '1.12.1'
default['cfncluster']['efa']['installer_url'] = "https://efa-installer.amazonaws.com/aws-efa-installer-#{node['cfncluster']['efa']['installer_version']}.tar.gz"
default['cfncluster']['enable_efa_gdr'] = "no"
default['cfncluster']['efa']['unsupported_aarch64_oses'] = %w[centos7 centos8]

# NICE DCV
default['cfncluster']['dcv_port'] = 8443
default['cfncluster']['dcv']['installed'] = 'yes'
default['cfncluster']['dcv']['version'] = '2021.1-10557'
if arm_instance?
  default['cfncluster']['dcv']['supported_os'] = %w[centos7 centos8 ubuntu18 amazon2]
  default['cfncluster']['dcv']['url_architecture_id'] = 'aarch64'
  default['cfncluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>8' => "79b6e256f186c2b5303879e12019ff034637e902cc167c848619a6caaa8001b1",
      '~>7' => "b3b47d8134800149758da92e4f5b97941245144a1cccf07bf44aa924d2b214a4"
    },
    'amazon' => { '2' => "b3b47d8134800149758da92e4f5b97941245144a1cccf07bf44aa924d2b214a4" },
    'ubuntu' => { '18.04' => "8e910b0de25fb744cb21c1a0a04a01d8a652d03bd836cd1f85d12f313652340e" }
  )
else
  default['cfncluster']['dcv']['supported_os'] = %w[centos8 centos7 ubuntu18 ubuntu20 amazon2]
  default['cfncluster']['dcv']['url_architecture_id'] = 'x86_64'
  default['cfncluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>8' => "bce3de696737e01fc9dc933a2d19c8d3cd3303419f07e8dd0e44696368d87a0d",
      '~>7' => "c0de28f38440c18757ef014e841b3bc79b7555e8b05904e10ddca1ce21d6e47f"
    },
    'amazon' => { '2' => "c0de28f38440c18757ef014e841b3bc79b7555e8b05904e10ddca1ce21d6e47f" },
    'ubuntu' => {
      '18.04' => "40908548266e7aa4ef2ca954eb25bf898d10ca00fc6b3d7b8b47cb3c9ff00ef9",
      '20.04' => "f8e9e9b64617066a25d67f4523a0c13f1b7eff22d9cb044aeebac9f97fa57cbf"
    }
  )
end
if node['platform'].to_s == 'ubuntu'
  # Unlike the other supported OSs, the DCV package names for Ubuntu use different architecture abbreviations than those used in the download URLs.
  default['cfncluster']['dcv']['package_architecture_id'] = arm_instance? ? 'arm64' : 'amd64'
end
default['cfncluster']['dcv']['package'] = value_for_platform(
  'centos' => {
    '~>8' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-el8-#{node['cfncluster']['dcv']['url_architecture_id']}",
    '~>7' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-el7-#{node['cfncluster']['dcv']['url_architecture_id']}"
  },
  'amazon' => { '2' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-el7-#{node['cfncluster']['dcv']['url_architecture_id']}" },
  'ubuntu' => {
    'default' => "nice-dcv-#{node['cfncluster']['dcv']['version']}-#{node['cfncluster']['cfn_base_os']}-#{node['cfncluster']['dcv']['url_architecture_id']}"
  }
)
default['cfncluster']['dcv']['server']['version'] = '2021.1.10557-1'
default['cfncluster']['dcv']['server'] = value_for_platform( # NICE DCV server package
  'centos' => {
    '~>8' => "nice-dcv-server-#{node['cfncluster']['dcv']['server']['version']}.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-dcv-server-#{node['cfncluster']['dcv']['server']['version']}.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-server-#{node['cfncluster']['dcv']['server']['version']}.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => {
    'default' => "nice-dcv-server_#{node['cfncluster']['dcv']['server']['version']}_#{node['cfncluster']['dcv']['package_architecture_id']}.#{node['cfncluster']['cfn_base_os']}.deb"
  }
)
default['cfncluster']['dcv']['xdcv']['version'] = '2021.1.392-1'
default['cfncluster']['dcv']['xdcv'] = value_for_platform( # required to create virtual sessions
  'centos' => {
    '~>8' => "nice-xdcv-#{node['cfncluster']['dcv']['xdcv']['version']}.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-xdcv-#{node['cfncluster']['dcv']['xdcv']['version']}.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-xdcv-#{node['cfncluster']['dcv']['xdcv']['version']}.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => {
    'default' => "nice-xdcv_#{node['cfncluster']['dcv']['xdcv']['version']}_#{node['cfncluster']['dcv']['package_architecture_id']}.#{node['cfncluster']['cfn_base_os']}.deb"
  }
)
default['cfncluster']['dcv']['gl']['version'] = '2021.1.937-1'
default['cfncluster']['dcv']['gl'] = value_for_platform( # required to enable GPU sharing
  'centos' => {
    '~>8' => "nice-dcv-gl-#{node['cfncluster']['dcv']['gl']['version']}.el8.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm",
    '~>7' => "nice-dcv-gl-#{node['cfncluster']['dcv']['gl']['version']}.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-gl-#{node['cfncluster']['dcv']['gl']['version']}.el7.#{node['cfncluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => {
    'default' => "nice-dcv-gl_#{node['cfncluster']['dcv']['gl']['version']}_#{node['cfncluster']['dcv']['package_architecture_id']}.#{node['cfncluster']['cfn_base_os']}.deb"
  }
)
default['cfncluster']['dcv']['url'] = "https://d1uj6qtbmh3dt5.cloudfront.net/2021.1/Servers/#{node['cfncluster']['dcv']['package']}.tgz"
# DCV external authenticator configuration
default['cfncluster']['dcv']['authenticator']['user'] = "dcvextauth"
default['cfncluster']['dcv']['authenticator']['user_home'] = "/home/#{node['cfncluster']['dcv']['authenticator']['user']}"
default['cfncluster']['dcv']['authenticator']['certificate'] = "/etc/parallelcluster/ext-auth-certificate.pem"
default['cfncluster']['dcv']['authenticator']['private_key'] = "/etc/parallelcluster/ext-auth-private-key.pem"
default['cfncluster']['dcv']['authenticator']['virtualenv'] = "dcv_authenticator_virtualenv"
default['cfncluster']['dcv']['authenticator']['virtualenv_path'] = [
  node['cfncluster']['system_pyenv_root'],
  'versions',
  node['cfncluster']['python-version'],
  'envs',
  node['cfncluster']['dcv']['authenticator']['virtualenv']
].join('/')

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
  # Config file used to set default MODULEPATH list
  default['cfncluster']['modulepath_config_file'] = value_for_platform(
    'centos' => {
      '~>8' => '/etc/environment-modules/modulespath',
      '~>7' => "#{node['cfncluster']['moduleshome']}/init/.modulespath"
    },
    'amazon' => { 'default' => "#{node['cfncluster']['moduleshome']}/init/.modulespath" }
  )

  case node['platform']
  when 'centos', 'redhat', 'scientific' # ~FC024
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel redhat-lsb mlocate lvm2 mpich-devel R atlas-devel
                                                blas-devel fftw-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                                libical-devel postgresql-devel postgresql-server sendmail libxml2-devel libglvnd-devel
                                                mdadm python python-pip libssh2-devel libgcrypt-devel libevent-devel glibc-static bind-utils
                                                iproute NetworkManager-config-routing-rules python3 python3-pip]
    if node['platform_version'].to_i >= 8
      # Do not install unversioned python
      default['cfncluster']['base_packages'].delete('python')
      default['cfncluster']['base_packages'].delete('python-pip')
      # iptables used in configure-pat.sh
      # gdisk required for FSx
      # environment-modules required for IntelMPI
      # libtirpc and libtirpc-devel required for SGE
      # cryptsetup used for ephemeral drive encryption
      default['cfncluster']['base_packages'].push(%w[iptables gdisk environment-modules libtirpc libtirpc-devel cryptsetup])
    end

    if node['platform_version'].to_i == 7 && node['kernel']['machine'] == 'aarch64'
      # Do not install bind-utils on centos7+arm due to issue with package checksum
      default['cfncluster']['base_packages'].delete('bind-utils')
    end

    default['cfncluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-optional'

  when 'amazon'
    default['cfncluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                                libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                                httpd boost-devel system-lsb mlocate atlas-devel fftw-devel glibc-static iproute
                                                libffi-devel dkms mysql-devel libedit-devel postgresql-devel postgresql-server
                                                sendmail cmake byacc libglvnd-devel mdadm libgcrypt-devel libevent-devel
                                                libxml2-devel perl-devel tar gzip bison flex gcc gcc-c++ patch
                                                rpm-build rpm-sign system-rpm-config cscope ctags diffstat doxygen elfutils
                                                gcc-gfortran git indent intltool patchutils rcs subversion swig systemtap curl
                                                jq wget python-pip NetworkManager-config-routing-rules libibverbs-utils
                                                librdmacm-utils python3 python3-pip]

    # Install R via amazon linux extras
    default['cfncluster']['alinux_extras'] = ['R3.4']
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
                                              tcl-dev automake autoconf libtool librrd-dev libapr1-dev libconfuse-dev
                                              apache2 libboost-dev libdb-dev tcsh libncurses5-dev libpam0g-dev libxt-dev
                                              libmotif-dev libxmu-dev libxft-dev libhwloc-dev man-db lvm2 libmpich-dev python
                                              r-base libblas-dev libfftw3-dev libffi-dev libxml2-dev mdadm
                                              libgcrypt20-dev libmysqlclient-dev libevent-dev iproute2 python3 python3-pip
                                              libatlas-base-dev libglvnd-dev linux-headers-aws]
  default['cfncluster']['sge']['url'] = 'https://deb.debian.org/debian/pool/main/g/gridengine/gridengine_8.1.9+dfsg.orig.tar.gz'
  default['cfncluster']['sge']['version'] = '8.1.9+dfsg-9'

  case node['platform_version']
  when '18.04'
    # Install libmpich12 and mpich explicitly to preserve existing behavior
    # libmpich-dev need to be removed after scheduler compilation due to a compatibility issue with efa installer v1.12.x
    default['cfncluster']['base_packages'].push('python-pip', 'python-parted', 'libmpich12', 'mpich')
  when '20.04'
    default['cfncluster']['base_packages'].push('python3-parted')
  end

  # Modulefile Directory
  default['cfncluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"
  # MODULESHOME
  default['cfncluster']['moduleshome'] = "/usr/share/modules"
  # Config file used to set default MODULEPATH list
  default['cfncluster']['modulepath_config_file'] = "#{node['cfncluster']['moduleshome']}/init/.modulespath"
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

# Default NFS mount options
default['cfncluster']['nfs']['hard_mount_options'] = 'hard,_netdev'

# Lustre defaults (for CentOS >=7.7 and Ubuntu)
default['cfncluster']['lustre']['public_key'] = value_for_platform(
  'centos' => { '>=7.7' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc" },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc" }
)
# Lustre repo string is built following the official doc
# https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html
# 'centos' is used for arm and 'el' for x86_64
default['cfncluster']['lustre']['centos7']['base_url_prefix'] = arm_instance? ? 'centos' : 'el'
default['cfncluster']['lustre']['base_url'] = value_for_platform(
  'centos' => {
    # node['kernel']['machine'] contains the architecture: 'x86_64' or 'aarch64'
    '>=8' => "https://fsx-lustre-client-repo.s3.amazonaws.com/el/8.#{find_rhel_minor_version}/#{node['kernel']['machine']}/",
    'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/#{default['cfncluster']['lustre']['centos7']['base_url_prefix']}/7.#{find_rhel_minor_version}/#{node['kernel']['machine']}/"
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

# Default gc_thresh values for performance at scale
default['cfncluster']['sysctl']['ipv4']['gc_thresh1'] = 0
default['cfncluster']['sysctl']['ipv4']['gc_thresh2'] = 15_360
default['cfncluster']['sysctl']['ipv4']['gc_thresh3'] = 16_384

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
default['cfncluster']['cfn_fsx_dns_name'] = nil
default['cfncluster']['cfn_fsx_mount_name'] = nil
default['cfncluster']['custom_node_package'] = nil
default['cfncluster']['custom_awsbatchcli_package'] = nil
default['cfncluster']['cfn_raid_parameters'] = 'NONE'
default['cfncluster']['cfn_raid_vol_ids'] = nil
default['cfncluster']['cfn_dns_domain'] = nil
default['cfncluster']['use_private_hostname'] = 'false'
default['cfncluster']['skip_install_recipes'] = 'yes'
default['cfncluster']['scheduler_queue_name'] = nil

# AWS domain
default['cfncluster']['aws_domain'] = aws_domain # ~FC044

# Official ami build
default['cfncluster']['is_official_ami_build'] = false

# Additional instance types data
default['cfncluster']['instance_types_data'] = nil
