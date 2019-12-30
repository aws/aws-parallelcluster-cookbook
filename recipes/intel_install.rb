# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: intel_install
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

case node['cfncluster']['cfn_node_type']
when 'MasterServer'

  # Downloads the intel-hpc-platform rpms
  bash "install intel hpc platform" do
    cwd node['cfncluster']['sources_dir']
    code <<-INTEL
      set -e
      yum-config-manager --add-repo http://yum.repos.intel.com/hpc-platform/el7/setup/intel-hpc-platform.repo
      yum-config-manager --save --setopt=intel-hpc-platform.skip_if_unavailable=true
      rpm --import http://yum.repos.intel.com/hpc-platform/el7/setup/PUBLIC_KEY.PUB
      yum -y install --downloadonly --downloaddir=/opt/intel/rpms intel-hpc-platform-*-#{node['cfncluster']['intelhpc']['version']}
    INTEL
    creates '/opt/intel/rpms'
  end

  # parallel studio is intel's optimized libraries, this is the runtime (free) version
  bash "install intel psxe" do
    cwd node['cfncluster']['sources_dir']
    code <<-INTEL
      set -e
      rpm --import https://yum.repos.intel.com/2019/setup/RPM-GPG-KEY-intel-psxe-runtime-2019
      yum -y install https://yum.repos.intel.com/2019/setup/intel-psxe-runtime-2019-reposetup-1-0.noarch.rpm
      yum-config-manager --save --setopt=intel-psxe-runtime-2019.skip_if_unavailable=true
      yum -y install intel-psxe-runtime-#{node['cfncluster']['psxe']['version']}
    INTEL
    creates '/opt/intel/psxe_runtime'
  end

  # intel optimized versions of python
  bash "install intel python" do
    cwd node['cfncluster']['sources_dir']
    code <<-INTEL
      set -e
      yum-config-manager --add-repo https://yum.repos.intel.com/intelpython/setup/intelpython.repo
      yum-config-manager --save --setopt=intelpython.skip_if_unavailable=true
      yum -y install intelpython2-#{node['cfncluster']['intelpython2']['version']} intelpython3-#{node['cfncluster']['intelpython3']['version']}
    INTEL
    creates '/opt/intel/intelpython2'
  end
end

# This rpm installs a file /etc/intel-hpc-platform-release that contains the INTEL_HPC_PLATFORM_VERSION
bash "install intel hpc platform" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTEL
    set -e
    yum install -y /opt/intel/rpms/*
  INTEL
  creates '/etc/intel-hpc-platform-release'
end

# create intelpython module directory
directory "#{node['cfncluster']['modulefile_dir']}/intelpython"

cookbook_file 'intelpython2_modulefile' do
  path "#{node['cfncluster']['modulefile_dir']}/intelpython/2"
  user 'root'
  group 'root'
  mode '0755'
end

cookbook_file 'intelpython3_modulefile' do
  path "#{node['cfncluster']['modulefile_dir']}/intelpython/3"
  user 'root'
  group 'root'
  mode '0755'
end

# intel optimized math kernel library
create_modulefile "#{node['cfncluster']['modulefile_dir']}/intelmkl" do
  source_path "/opt/intel/psxe_runtime/linux/mkl/bin/mklvars.sh"
  modulefile "#{node['cfncluster']['psxe']['version']}"
end

# intel psxe
create_modulefile "#{node['cfncluster']['modulefile_dir']}/intelpsxe" do
  source_path "/opt/intel/psxe_runtime/linux/bin/psxevars.sh"
  modulefile "#{node['cfncluster']['psxe']['version']}"
end
