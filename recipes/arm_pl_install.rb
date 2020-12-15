# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: arm_pl_install
#
# Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return unless node['conditions']['arm_pl_supported']

armpl_installer = "#{node['cfncluster']['sources_dir']}/arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}_gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.tar"
armpl_url = "https://#{node['cfncluster']['cfn_region']}-aws-parallelcluster.s3.#{node['cfncluster']['cfn_region']}.#{aws_domain}/#{node['cfncluster']['armpl']['url']}"

# fetch armpl installer script
remote_file armpl_installer do
  source armpl_url
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?("/opt/arm/armpl/#{node['cfncluster']['armpl']['version']}") }
end

bash "install arm performance library" do
  cwd node['cfncluster']['sources_dir']
  code <<-ARMPL
    set -e
    tar -xf arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}_gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.tar
    cd arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}/
    ./arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}.sh --accept --install-to /opt/arm/armpl/#{node['cfncluster']['armpl']['version']}
    cd ..
    rm -rf arm-performance-libraries_#{node['cfncluster']['armpl']['version']}_#{node['cfncluster']['armpl']['platform']}*
  ARMPL
  creates "/opt/arm/armpl/#{node['cfncluster']['armpl']['version']}"
end

# create armpl module directory
directory "#{node['cfncluster']['modulefile_dir']}/armpl"

# arm performance library modulefile configuration
template "#{node['cfncluster']['modulefile_dir']}/armpl/#{node['cfncluster']['armpl']['version']}" do
  source 'armpl_modulefile.erb'
  user 'root'
  group 'root'
  mode '0755'
end

gcc_tarball = "#{node['cfncluster']['sources_dir']}/gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']}.tar.gz"

# Get gcc tarball
remote_file gcc_tarball do
  source node['cfncluster']['armpl']['gcc']['url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(gcc_tarball) }
end

# Install gcc
bash 'make install' do
  user 'root'
  group 'root'
  cwd node['cfncluster']['sources_dir']
  code <<-GCC
      set -e

      tar -xf #{gcc_tarball}
      cd gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']}
      ./contrib/download_prerequisites
      mkdir build && cd build
      ../configure --prefix=/opt/arm/armpl/gcc/#{node['cfncluster']['armpl']['gcc']['major_minor_version']}.#{node['cfncluster']['armpl']['gcc']['patch_version']} --disable-bootstrap --enable-checking=release --enable-languages=c,c++,fortran --disable-multilib
      CORES=$(grep processor /proc/cpuinfo | wc -l)
      make -j $CORES
      make install
  GCC
  creates '/opt/arm/armpl/gcc'
end

gcc_modulefile = "/opt/arm/armpl/#{node['cfncluster']['armpl']['version']}/modulefiles/armpl/gcc-#{node['cfncluster']['armpl']['gcc']['major_minor_version']}"

# gcc modulefile configuration
template gcc_modulefile do
  source 'gcc_modulefile.erb'
  user 'root'
  group 'root'
  mode '0755'
end