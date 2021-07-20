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
default['cluster']['base_dir'] = '/opt/parallelcluster'
default['cluster']['sources_dir'] = "#{node['cluster']['base_dir']}/sources"
default['cluster']['scripts_dir'] = "#{node['cluster']['base_dir']}/scripts"
default['cluster']['license_dir'] = "#{node['cluster']['base_dir']}/licenses"
default['cluster']['configs_dir'] = "#{node['cluster']['base_dir']}/configs"

# Cluster config
default['cluster']['cluster_s3_bucket'] = nil
default['cluster']['cluster_config_s3_key'] = nil
default['cluster']['cluster_config_version'] = nil
default['cluster']['instance_types_data_s3_key'] = nil
default['cluster']['cluster_config_path'] = "#{node['cluster']['configs_dir']}/cluster-config.yaml"
default['cluster']['instance_types_data_path'] = "#{node['cluster']['configs_dir']}/instance-types-data.json"
default['cluster']['reserved_base_uid'] = 400

# Python Version
default['cluster']['python-version'] = '3.7.10'
# plcuster-specific pyenv system installation root
default['cluster']['system_pyenv_root'] = "#{node['cluster']['base_dir']}/pyenv"
# Virtualenv Cookbook Name
default['cluster']['cookbook_virtualenv'] = 'cookbook_virtualenv'
# Virtualenv Node Name
default['cluster']['node_virtualenv'] = 'node_virtualenv'
# Virtualenv AWSBatch Name
default['cluster']['awsbatch_virtualenv'] = 'awsbatch_virtualenv'
# Cookbook Virtualenv Path
default['cluster']['cookbook_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['cookbook_virtualenv']}"
# Node Virtualenv Path
default['cluster']['node_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['node_virtualenv']}"
# AWSBatch Virtualenv Path
default['cluster']['awsbatch_virtualenv_path'] = "#{node['cluster']['system_pyenv_root']}/versions/#{node['cluster']['python-version']}/envs/#{node['cluster']['awsbatch_virtualenv']}"

# Intel Packages
default['cluster']['psxe']['version'] = '2020.4-17'
default['cluster']['psxe']['noarch_packages'] = %w[intel-tbb-common-runtime intel-mkl-common-runtime intel-psxe-common-runtime
                                                   intel-ipp-common-runtime intel-ifort-common-runtime intel-icc-common-runtime
                                                   intel-daal-common-runtime intel-comp-common-runtime]
default['cluster']['psxe']['archful_packages']['i486'] = %w[intel-tbb-runtime intel-tbb-libs-runtime intel-comp-runtime
                                                            intel-daal-runtime intel-icc-runtime intel-ifort-runtime
                                                            intel-ipp-runtime intel-mkl-runtime intel-openmp-runtime]
default['cluster']['psxe']['archful_packages']['x86_64'] = node['cluster']['psxe']['archful_packages']['i486'] + %w[intel-mpi-runtime]
default['cluster']['intelhpc']['platform_name'] = value_for_platform(
  'centos' => {
    '~>7' => 'el7'
  }
)
default['cluster']['intelhpc']['packages'] = %w[intel-hpc-platform-core-intel-runtime-advisory intel-hpc-platform-compat-hpc-advisory
                                                intel-hpc-platform-core intel-hpc-platform-core-advisory intel-hpc-platform-hpc-cluster
                                                intel-hpc-platform-compat-hpc intel-hpc-platform-core-intel-runtime]
default['cluster']['intelhpc']['version'] = '2018.0-7'
default['cluster']['intelpython2']['version'] = '2019.4-088'
default['cluster']['intelpython3']['version'] = '2020.2-902'

# Intel MPI
default['cluster']['intelmpi']['version'] = '2019.8.254'
default['cluster']['intelmpi']['modulefile'] = "/opt/intel/impi/#{node['cluster']['intelmpi']['version']}/intel64/modulefiles/mpi"
default['cluster']['intelmpi']['kitchen_test_string'] = 'Version 2019 Update 8'

# Arm Performance Library
default['cluster']['armpl']['major_minor_version'] = '21.0'
default['cluster']['armpl']['patch_version'] = '0'
default['cluster']['armpl']['version'] = "#{node['cluster']['armpl']['major_minor_version']}.#{node['cluster']['armpl']['patch_version']}"

default['cluster']['armpl']['gcc']['major_minor_version'] = '9.3'
default['cluster']['armpl']['gcc']['patch_version'] = '0'
default['cluster']['armpl']['gcc']['url'] = [
  'https://ftp.gnu.org/gnu/gcc',
  "gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}",
  "gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}.tar.gz"
].join('/')
default['cluster']['armpl']['platform'] = value_for_platform(
  'centos' => { '~>7' => 'RHEL-7' },
  'amazon' => { '2' => 'RHEL-8' },
  'ubuntu' => {
    '18.04' => 'Ubuntu-18.04',
    '20.04' => 'Ubuntu-20.04'
  }
)
default['cluster']['armpl']['url'] = [
  'archives/armpl',
  node['cluster']['armpl']['platform'],
  "arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}_gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.tar"
].join('/')

# Python packages
default['cluster']['parallelcluster-version'] = '3.0.0'
default['cluster']['parallelcluster-cookbook-version'] = '3.0.0'
default['cluster']['parallelcluster-node-version'] = '3.0.0'
default['cluster']['parallelcluster-awsbatch-cli-version'] = '1.0.0'

# URLs to software packages used during install recipes
# Slurm software
default['cluster']['slurm_plugin_dir'] = '/etc/parallelcluster/slurm_plugin'
default['cluster']['slurm']['version'] = '20-11-7-1'
default['cluster']['slurm']['url'] = "https://github.com/SchedMD/slurm/archive/slurm-#{node['cluster']['slurm']['version']}.tar.gz"
default['cluster']['slurm']['sha1'] = 'ce927fbf2f7d5f908ed87c5d521abc696b9a2508'
default['cluster']['slurm']['user'] = 'slurm'
default['cluster']['slurm']['user_id'] = node['cluster']['reserved_base_uid'] + 1
default['cluster']['slurm']['group'] = node['cluster']['slurm']['user']
default['cluster']['slurm']['group_id'] = node['cluster']['slurm']['user_id']
# PMIx software
default['cluster']['pmix']['version'] = '3.1.5'
default['cluster']['pmix']['url'] = "https://github.com/openpmix/openpmix/releases/download/v#{node['cluster']['pmix']['version']}/pmix-#{node['cluster']['pmix']['version']}.tar.gz"
default['cluster']['pmix']['sha1'] = '36bfb962858879cefa7a04a633c1b6984cea03ec'
# Munge
default['cluster']['munge']['munge_version'] = '0.5.14'
default['cluster']['munge']['munge_url'] = "https://github.com/dun/munge/archive/munge-#{node['cluster']['munge']['munge_version']}.tar.gz"
default['cluster']['munge']['user'] = 'munge'
default['cluster']['munge']['user_id'] = node['cluster']['reserved_base_uid'] + 2
default['cluster']['munge']['group'] = node['cluster']['munge']['user']
default['cluster']['munge']['group_id'] = node['cluster']['munge']['user_id']

# NVIDIA
default['cluster']['nvidia']['enabled'] = 'no'
default['cluster']['nvidia']['driver_version'] = '460.73.01'
default['cluster']['nvidia']['driver_url'] = 'https://us.download.nvidia.com/tesla/460.73.01/NVIDIA-Linux-x86_64-460.73.01.run'
default['cluster']['nvidia']['cuda_version'] = '11.3'
default['cluster']['nvidia']['cuda_url'] = 'https://developer.download.nvidia.com/compute/cuda/11.3.0/local_installers/cuda_11.3.0_465.19.01_linux.run'

# NVIDIA fabric-manager
default['cluster']['nvidia']['fabricmanager']['package'] = "nvidia-fabricmanager-460"
default['cluster']['nvidia']['fabricmanager']['repository_key'] = "7fa2af80.pub"
default['cluster']['nvidia']['fabricmanager']['version'] = value_for_platform(
  'default' => node['cluster']['nvidia']['driver_version'],
  # with apt a star is needed to match the package version
  'ubuntu' => { 'default' => "#{node['cluster']['nvidia']['driver_version']}*" }
)
default['cluster']['nvidia']['fabricmanager']['repository_uri'] = value_for_platform(
  'default' => "https://developer.download.nvidia._domain_/compute/cuda/repos/rhel7/x86_64",
  'ubuntu' => { 'default' => "https://developer.download.nvidia._domain_/compute/cuda/repos/#{node['cluster']['base_os']}/x86_64" }
)

# EFA
default['cluster']['efa']['installer_version'] = '1.12.2'
default['cluster']['efa']['installer_url'] = "https://efa-installer.amazonaws.com/aws-efa-installer-#{node['cluster']['efa']['installer_version']}.tar.gz"
default['cluster']['enable_efa_gdr'] = "no"
default['cluster']['efa']['unsupported_aarch64_oses'] = %w[centos7]

# NICE DCV
default['cluster']['dcv_port'] = 8443
default['cluster']['dcv']['installed'] = 'yes'
default['cluster']['dcv']['version'] = '2021.1-10557'
if arm_instance?
  default['cluster']['dcv']['supported_os'] = %w[centos7 ubuntu18 amazon2]
  default['cluster']['dcv']['url_architecture_id'] = 'aarch64'
  default['cluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
      '~>7' => "b3b47d8134800149758da92e4f5b97941245144a1cccf07bf44aa924d2b214a4"
    },
    'amazon' => { '2' => "b3b47d8134800149758da92e4f5b97941245144a1cccf07bf44aa924d2b214a4" },
    'ubuntu' => { '18.04' => "8e910b0de25fb744cb21c1a0a04a01d8a652d03bd836cd1f85d12f313652340e" }
  )
else
  default['cluster']['dcv']['supported_os'] = %w[centos7 ubuntu18 ubuntu20 amazon2]
  default['cluster']['dcv']['url_architecture_id'] = 'x86_64'
  default['cluster']['dcv']['sha256sum'] = value_for_platform(
    'centos' => {
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
  default['cluster']['dcv']['package_architecture_id'] = arm_instance? ? 'arm64' : 'amd64'
end
default['cluster']['dcv']['package'] = value_for_platform(
  'centos' => {
    '~>7' => "nice-dcv-#{node['cluster']['dcv']['version']}-el7-#{node['cluster']['dcv']['url_architecture_id']}"
  },
  'amazon' => { '2' => "nice-dcv-#{node['cluster']['dcv']['version']}-el7-#{node['cluster']['dcv']['url_architecture_id']}" },
  'ubuntu' => {
    'default' => "nice-dcv-#{node['cluster']['dcv']['version']}-#{node['cluster']['base_os']}-#{node['cluster']['dcv']['url_architecture_id']}"
  }
)
default['cluster']['dcv']['server']['version'] = '2021.1.10557-1'
default['cluster']['dcv']['server'] = value_for_platform( # NICE DCV server package
  'centos' => {
    '~>7' => "nice-dcv-server-#{node['cluster']['dcv']['server']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-server-#{node['cluster']['dcv']['server']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => {
    'default' => "nice-dcv-server_#{node['cluster']['dcv']['server']['version']}_#{node['cluster']['dcv']['package_architecture_id']}.#{node['cluster']['base_os']}.deb"
  }
)
default['cluster']['dcv']['xdcv']['version'] = '2021.1.392-1'
default['cluster']['dcv']['xdcv'] = value_for_platform( # required to create virtual sessions
  'centos' => {
    '~>7' => "nice-xdcv-#{node['cluster']['dcv']['xdcv']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-xdcv-#{node['cluster']['dcv']['xdcv']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => {
    'default' => "nice-xdcv_#{node['cluster']['dcv']['xdcv']['version']}_#{node['cluster']['dcv']['package_architecture_id']}.#{node['cluster']['base_os']}.deb"
  }
)
default['cluster']['dcv']['gl']['version'] = '2021.1.937-1'
default['cluster']['dcv']['gl'] = value_for_platform( # required to enable GPU sharing
  'centos' => {
    '~>7' => "nice-dcv-gl-#{node['cluster']['dcv']['gl']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm"
  },
  'amazon' => { '2' => "nice-dcv-gl-#{node['cluster']['dcv']['gl']['version']}.el7.#{node['cluster']['dcv']['url_architecture_id']}.rpm" },
  'ubuntu' => {
    'default' => "nice-dcv-gl_#{node['cluster']['dcv']['gl']['version']}_#{node['cluster']['dcv']['package_architecture_id']}.#{node['cluster']['base_os']}.deb"
  }
)
default['cluster']['dcv']['url'] = "https://d1uj6qtbmh3dt5.cloudfront.net/2021.1/Servers/#{node['cluster']['dcv']['package']}.tgz"
# DCV external authenticator configuration
default['cluster']['dcv']['authenticator']['user'] = "dcvextauth"
default['cluster']['dcv']['authenticator']['user_id'] = node['cluster']['reserved_base_uid'] + 3
default['cluster']['dcv']['authenticator']['group'] = node['cluster']['dcv']['authenticator']['user']
default['cluster']['dcv']['authenticator']['group_id'] = node['cluster']['dcv']['authenticator']['user_id']
default['cluster']['dcv']['authenticator']['user_home'] = "/home/#{node['cluster']['dcv']['authenticator']['user']}"
default['cluster']['dcv']['authenticator']['certificate'] = "/etc/parallelcluster/ext-auth-certificate.pem"
default['cluster']['dcv']['authenticator']['private_key'] = "/etc/parallelcluster/ext-auth-private-key.pem"
default['cluster']['dcv']['authenticator']['virtualenv'] = "dcv_authenticator_virtualenv"
default['cluster']['dcv']['authenticator']['virtualenv_path'] = [
  node['cluster']['system_pyenv_root'],
  'versions',
  node['cluster']['python-version'],
  'envs',
  node['cluster']['dcv']['authenticator']['virtualenv']
].join('/')

# CloudWatch Agent
default['cluster']['cloudwatch']['public_key_url'] = "https://s3.amazonaws.com/amazoncloudwatch-agent/assets/amazon-cloudwatch-agent.gpg"
default['cluster']['cloudwatch']['public_key_local_path'] = "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.gpg"

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
default['cluster']['filehandle_limit'] = 10_000
default['cluster']['memory_limit'] = 'unlimited'

# Platform defaults
case node['platform_family']
when 'rhel', 'amazon'

  default['cluster']['kernel_devel_pkg']['name'] = "kernel-devel"
  default['cluster']['kernel_devel_pkg']['version'] = node['kernel']['release'].chomp('.x86_64').chomp('.aarch64')

  # Modulefile Directory
  default['cluster']['modulefile_dir'] = "/usr/share/Modules/modulefiles"
  # MODULESHOME
  default['cluster']['moduleshome'] = "/usr/share/Modules"
  # Config file used to set default MODULEPATH list
  default['cluster']['modulepath_config_file'] = value_for_platform(
    'centos' => {
      '~>7' => "#{node['cluster']['moduleshome']}/init/.modulespath"
    },
    'amazon' => { 'default' => "#{node['cluster']['moduleshome']}/init/.modulespath" }
  )

  case node['platform']
  when 'centos', 'redhat', 'scientific' # ~FC024
    default['cluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                             libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                             httpd boost-devel redhat-lsb mlocate lvm2 mpich-devel R atlas-devel
                                             blas-devel fftw-devel libffi-devel openssl-devel dkms mariadb-devel libedit-devel
                                             libical-devel postgresql-devel postgresql-server sendmail libxml2-devel libglvnd-devel
                                             mdadm python python-pip libssh2-devel libgcrypt-devel libevent-devel glibc-static bind-utils
                                             iproute NetworkManager-config-routing-rules python3 python3-pip iptables libcurl-devel]
    default['cluster']['rhel']['extra_repo'] = 'rhui-REGION-rhel-server-optional'

    if node['platform_version'].to_i == 7 && node['kernel']['machine'] == 'aarch64'
      # Do not install bind-utils on centos7+arm due to issue with package checksum
      default['cluster']['base_packages'].delete('bind-utils')
    end

  when 'amazon'
    default['cluster']['base_packages'] = %w[vim ksh tcsh zsh openssl-devel ncurses-devel pam-devel net-tools openmotif-devel
                                             libXmu-devel hwloc-devel libdb-devel tcl-devel automake autoconf pyparted libtool
                                             httpd boost-devel system-lsb mlocate atlas-devel fftw-devel glibc-static iproute
                                             libffi-devel dkms mysql-devel libedit-devel postgresql-devel postgresql-server
                                             sendmail cmake byacc libglvnd-devel mdadm libgcrypt-devel libevent-devel
                                             libxml2-devel perl-devel tar gzip bison flex gcc gcc-c++ patch
                                             rpm-build rpm-sign system-rpm-config cscope ctags diffstat doxygen elfutils
                                             gcc-gfortran git indent intltool patchutils rcs subversion swig systemtap curl
                                             jq wget python-pip NetworkManager-config-routing-rules libibverbs-utils
                                             librdmacm-utils python3 python3-pip iptables libcurl-devel]

    # Install R via amazon linux extras
    default['cluster']['alinux_extras'] = ['R3.4']
  end

  default['cluster']['chrony']['service'] = "chronyd"
  default['cluster']['chrony']['conf'] = "/etc/chrony.conf"

when 'debian'
  default['openssh']['server']['subsystem'] = 'sftp internal-sftp'
  default['cluster']['base_packages'] = %w[vim ksh tcsh zsh libssl-dev ncurses-dev libpam-dev net-tools libhwloc-dev dkms
                                           tcl-dev automake autoconf libtool librrd-dev libapr1-dev libconfuse-dev
                                           apache2 libboost-dev libdb-dev tcsh libncurses5-dev libpam0g-dev libxt-dev
                                           libmotif-dev libxmu-dev libxft-dev libhwloc-dev man-db lvm2 libmpich-dev python
                                           r-base libblas-dev libfftw3-dev libffi-dev libxml2-dev mdadm
                                           libgcrypt20-dev libmysqlclient-dev libevent-dev iproute2 python3 python3-pip
                                           libatlas-base-dev libglvnd-dev linux-headers-aws iptables libcurl4-openssl-dev]

  case node['platform_version']
  when '18.04'
    # Install libmpich12 and mpich explicitly to preserve existing behavior
    # libmpich-dev need to be removed after scheduler compilation due to a compatibility issue with efa installer v1.12.x
    default['cluster']['base_packages'].push('python-pip', 'python-parted', 'libmpich12', 'mpich')
  when '20.04'
    default['cluster']['base_packages'].push('python3-parted')
  end

  # Modulefile Directory
  default['cluster']['modulefile_dir'] = "/usr/share/modules/modulefiles"
  # MODULESHOME
  default['cluster']['moduleshome'] = "/usr/share/modules"
  # Config file used to set default MODULEPATH list
  default['cluster']['modulepath_config_file'] = "#{node['cluster']['moduleshome']}/init/.modulespath"
  default['cluster']['kernel_generic_pkg'] = "linux-generic"
  default['cluster']['chrony']['service'] = "chrony"
  default['cluster']['chrony']['conf'] = "/etc/chrony/chrony.conf"

  if Chef::VersionConstraint.new('>= 15.04').include?(node['platform_version'])
    default['nfs']['service_provider']['idmap'] = Chef::Provider::Service::Systemd
    default['nfs']['service_provider']['portmap'] = Chef::Provider::Service::Systemd
    default['nfs']['service_provider']['lock'] = Chef::Provider::Service::Systemd
    default['nfs']['service']['lock'] = 'rpc-statd'
    default['nfs']['service']['idmap'] = 'nfs-idmapd'
  end
end

# Default NFS mount options
default['cluster']['nfs']['hard_mount_options'] = 'hard,_netdev,noatime'

# Lustre defaults (for CentOS >=7.7 and Ubuntu)
default['cluster']['lustre']['public_key'] = value_for_platform(
  'centos' => { '>=7.7' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-rpm-public-key.asc" },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo-public-keys.s3.amazonaws.com/fsx-ubuntu-public-key.asc" }
)
# Lustre repo string is built following the official doc
# https://docs.aws.amazon.com/fsx/latest/LustreGuide/install-lustre-client.html
# 'centos' is used for arm and 'el' for x86_64
default['cluster']['lustre']['centos7']['base_url_prefix'] = arm_instance? ? 'centos' : 'el'
default['cluster']['lustre']['base_url'] = value_for_platform(
  'centos' => {
    # node['kernel']['machine'] contains the architecture: 'x86_64' or 'aarch64'
    'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/#{default['cluster']['lustre']['centos7']['base_url_prefix']}/7.#{find_rhel_minor_version}/#{node['kernel']['machine']}/"
  },
  'ubuntu' => { 'default' => "https://fsx-lustre-client-repo.s3.amazonaws.com/ubuntu" }
)
# Lustre defaults (for CentOS 7.6 and 7.5 only)
default['cluster']['lustre']['version'] = value_for_platform(
  'centos' => {
    '7.6' => "2.10.6",
    '7.5' => "2.10.5"
  }
)
default['cluster']['lustre']['kmod_url'] = value_for_platform(
  'centos' => {
    '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/kmod-lustre-client-2.10.6-1.el7.x86_64.rpm",
    '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/kmod-lustre-client-2.10.5-1.el7.x86_64.rpm"
  }
)
default['cluster']['lustre']['client_url'] = value_for_platform(
  'centos' => {
    '7.6' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.6/el7/client/RPMS/x86_64/lustre-client-2.10.6-1.el7.x86_64.rpm",
    '7.5' => "https://downloads.whamcloud.com/public/lustre/lustre-2.10.5/el7.5.1804/client/RPMS/x86_64/lustre-client-2.10.5-1.el7.x86_64.rpm"
  }
)

# Default gc_thresh values for performance at scale
default['cluster']['sysctl']['ipv4']['gc_thresh1'] = 0
default['cluster']['sysctl']['ipv4']['gc_thresh2'] = 15_360
default['cluster']['sysctl']['ipv4']['gc_thresh3'] = 16_384

# ParallelCluster internal variables (also in /etc/parallelcluster/cfnconfig)
default['cluster']['region'] = 'us-east-1'
default['cluster']['stack_name'] = nil
default['cluster']['ddb_table'] = nil
default['cluster']['log_group_name'] = "NONE"
default['cluster']['node_type'] = nil
default['cluster']['preinstall'] = 'NONE'
default['cluster']['preinstall_args'] = 'NONE'
default['cluster']['proxy'] = 'NONE'
default['cluster']['postinstall'] = 'NONE'
default['cluster']['postinstall_args'] = 'NONE'
default['cluster']['scheduler'] = 'slurm'
default['cluster']['scheduler_slots'] = 'vcpus'
default['cluster']['disable_hyperthreading_manually'] = 'false'
default['cluster']['instance_slots'] = '1'
default['cluster']['volume'] = nil
default['cluster']['volume_fs_type'] = 'ext4'
default['cluster']['encrypted_ephemeral'] = false
default['cluster']['ephemeral_dir'] = '/scratch'
default['cluster']['ebs_shared_dirs'] = '/shared'
default['cluster']['efs_shared_dir'] = 'NONE'
default['cluster']['efs_fs_id'] = nil
default['cluster']['head_node'] = nil
default['cluster']['head_node_private_ip'] = nil
default['cluster']['cluster_admin_user'] = 'pcluster-admin'
default['cluster']['cluster_admin_user_id'] = node['cluster']['reserved_base_uid']
default['cluster']['cluster_admin_group'] = node['cluster']['cluster_admin_user']
default['cluster']['cluster_admin_group_id'] = node['cluster']['cluster_admin_user_id']
default['cluster']['cluster_user'] = 'ec2-user'
default['cluster']['fsx_options'] = 'NONE'
default['cluster']['fsx_fs_id'] = nil
default['cluster']['fsx_dns_name'] = nil
default['cluster']['fsx_mount_name'] = nil
default['cluster']['custom_node_package'] = nil
default['cluster']['custom_awsbatchcli_package'] = nil
default['cluster']['raid_parameters'] = 'NONE'
default['cluster']['raid_vol_ids'] = nil
default['cluster']['dns_domain'] = nil
default['cluster']['use_private_hostname'] = 'false'
default['cluster']['skip_install_recipes'] = 'yes'
default['cluster']['scheduler_queue_name'] = nil

# AWS domain
default['cluster']['aws_domain'] = aws_domain # ~FC044

# Official ami build
default['cluster']['is_official_ami_build'] = false

# Additional instance types data
default['cluster']['instance_types_data'] = nil

# IMDS
default['cluster']['head_node_imds_secured'] = 'true'
default['cluster']['head_node_imds_allowed_users'] = ['root', node['cluster']['cluster_admin_user']]
default['cluster']['head_node_imds_allowed_users'].append('dcv') if node['cluster']['dcv_enabled'] == 'head_node'
