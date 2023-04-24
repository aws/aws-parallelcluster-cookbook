# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

action :setup do
  return unless node['conditions']['arm_pl_supported']

  modules 'Prerequisite: Environment modules'
  build_tools 'Prerequisite: build tools'
  package %w(wget bzip2)

  action_arm_pl_prerequisite

  armpl_installer = "#{node['cluster']['sources_dir']}/"\
                    "arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}_gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.tar"
  armpl_url = "https://#{node['cluster']['region']}-aws-parallelcluster.s3.#{node['cluster']['region']}.#{aws_domain}/#{node['cluster']['armpl']['url']}"

  # fetch armpl installer script
  remote_file armpl_installer do
    source armpl_url
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?("/opt/arm/armpl/#{node['cluster']['armpl']['version']}") }
  end

  bash "install arm performance library" do
    cwd node['cluster']['sources_dir']
    code <<-ARMPL
      set -e
      tar -xf arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}_gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.tar
      cd arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}/
      ./arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}.sh --accept --install-to /opt/arm/armpl/#{node['cluster']['armpl']['version']}
      cd ..
      rm -rf arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}*
    ARMPL
    creates "/opt/arm/armpl/#{node['cluster']['armpl']['version']}"
  end

  # create armpl module directory
  directory "#{node['cluster']['modulefile_dir']}/armpl"

  # arm performance library modulefile configuration
  template "#{node['cluster']['modulefile_dir']}/armpl/#{node['cluster']['armpl']['version']}" do
    source 'arm_pl/armpl_modulefile.erb'
    user 'root'
    group 'root'
    mode '0755'
  end

  gcc_tarball = "#{node['cluster']['sources_dir']}/gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}.tar.gz"

  # Get gcc tarball
  remote_file gcc_tarball do
    source node['cluster']['armpl']['gcc']['url']
    mode '0644'
    retries 5
    retry_delay 10
    ssl_verify_mode :verify_none
    action :create_if_missing
  end

  # Install gcc
  bash 'make install' do
    user 'root'
    group 'root'
    cwd node['cluster']['sources_dir']
    code <<-GCC
        set -e

        # Remove dir if it exists. This happens in case of retries.
        rm -rf gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}
        tar -xf #{gcc_tarball}
        cd gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']}
        # Patch the download_prerequisites script to download over https and not ftp. This works better in China regions.
        sed -i "s#ftp://gcc\.gnu\.org#https://gcc.gnu.org#g" ./contrib/download_prerequisites
        ./contrib/download_prerequisites
        mkdir build && cd build
        ../configure --prefix=/opt/arm/armpl/gcc/#{node['cluster']['armpl']['gcc']['major_minor_version']}.#{node['cluster']['armpl']['gcc']['patch_version']} --disable-bootstrap --enable-checking=release --enable-languages=c,c++,fortran --disable-multilib
        CORES=$(grep processor /proc/cpuinfo | wc -l)
        make -j $CORES
        make install
    GCC
    retries 5
    retry_delay 10
    creates '/opt/arm/armpl/gcc'
  end

  gcc_modulefile = "/opt/arm/armpl/#{node['cluster']['armpl']['version']}/modulefiles/armpl/gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}"

  # gcc modulefile configuration
  template gcc_modulefile do
    source 'arm_pl/gcc_modulefile.erb'
    user 'root'
    group 'root'
    mode '0755'
  end
end
