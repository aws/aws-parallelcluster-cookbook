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

property :sources_dir, String
property :region, String
property :aws_domain, String

# Find the latest version of Arm Performance Libraries (ArmPL) here:
# https://developer.arm.com/downloads/-/arm-compiler-for-linux
#
# Usually we upgrade gcc version as well (see below).
# We upload ArmPL to a ParallelCluster bucket (account for it in scope of the upgrade) and download it from there
# to install ArmPL on the AMI.
# We download gcc directly from gnu.org repository to install correct gcc version on the AMI.
property :armpl_major_minor_version, String, default: '23.10'
property :gcc_patch_version, String, default: '0'

action :arm_pl_prerequisite do
  # Do nothing
end

action :setup do
  return unless node['conditions']['arm_pl_supported']

  new_resource.sources_dir = new_resource.sources_dir || node['cluster']['sources_dir']
  new_resource.region = new_resource.region || node['cluster']['region']
  new_resource.aws_domain = new_resource.aws_domain || aws_domain

  directory new_resource.sources_dir do
    recursive true
  end

  modules 'Prerequisite: Environment modules'
  build_tools 'Prerequisite: build tools'
  package %w(wget bzip2)

  action_arm_pl_prerequisite

  armpl_version = "#{new_resource.armpl_major_minor_version}"
  armpl_tarball_name = "arm-performance-libraries_#{armpl_version}_#{armpl_platform}_gcc-#{gcc_major_minor_version}.tar"

  armpl_url = %W(
    https://#{new_resource.region}-aws-parallelcluster.s3.#{new_resource.region}.#{new_resource.aws_domain}
    archives/armpl/#{armpl_platform}
    #{armpl_tarball_name}
  ).join('/')

  armpl_installer = "#{new_resource.sources_dir}/#{armpl_tarball_name}"

  armpl_name = "arm-performance-libraries_#{armpl_version}_#{armpl_platform}"

  # download ArmPL tarball
  remote_file armpl_installer do
    source armpl_url
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?("/opt/arm/armpl/#{armpl_version}") }
  end

  bash "install arm performance library" do
    cwd new_resource.sources_dir
    code <<-ARMPL
      set -e
      tar -xf #{armpl_tarball_name}
      cd #{armpl_name}/
      ./#{armpl_name}.sh --accept --install-to /opt/arm/armpl/#{armpl_version}
      cd ..
      rm -rf #{armpl_name}*
    ARMPL
    creates "/opt/arm/armpl/#{armpl_version}"
  end

  # create armpl module directory
  directory "#{modulefile_dir}/armpl"

  armpl_license_dir = if new_resource.armpl_major_minor_version == "21.0"
                        "/opt/arm/armpl/#{armpl_version}/arm-performance-libraries_#{new_resource.armpl_major_minor_version}_gcc-#{gcc_major_minor_version}/license_terms"
                      else
                        "/opt/arm/armpl/#{armpl_version}/arm-performance-libraries_#{armpl_version}_gcc-#{gcc_major_minor_version}/license_terms"
                      end

  # arm performance library modulefile configuration
  template "#{modulefile_dir}/armpl/#{armpl_version}" do
    source 'arm_pl/armpl_modulefile.erb'
    cookbook 'aws-parallelcluster-platform'
    user 'root'
    group 'root'
    mode '0755'
    variables(
      armpl_version: armpl_version,
      armpl_major_minor_version: new_resource.armpl_major_minor_version,
      armpl_license_dir: armpl_license_dir,
      gcc_major_minor_version: gcc_major_minor_version
    )
  end

  gcc_version = "#{gcc_major_minor_version}.#{new_resource.gcc_patch_version}"
  gcc_url = "https://ftp.gnu.org/gnu/gcc/gcc-#{gcc_version}/gcc-#{gcc_version}.tar.gz"
  gcc_tarball = "#{new_resource.sources_dir}/gcc-#{gcc_version}.tar.gz"

  # Get gcc tarball
  remote_file gcc_tarball do
    source gcc_url
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
    cwd new_resource.sources_dir
    code <<-GCC
        set -e

        # Remove dir if it exists. This happens in case of retries.
        rm -rf gcc-#{gcc_version}
        tar -xf #{gcc_tarball}
        cd gcc-#{gcc_version}
        # Patch the download_prerequisites script to download over https and not ftp. This works better in China regions.
        sed -i "s#ftp://gcc\.gnu\.org#https://gcc.gnu.org#g" ./contrib/download_prerequisites
        ./contrib/download_prerequisites
        mkdir build && cd build
        ../configure --prefix=/opt/arm/armpl/gcc/#{gcc_version} --disable-bootstrap --enable-checking=release --enable-languages=c,c++,fortran --disable-multilib
        CORES=$(grep processor /proc/cpuinfo | wc -l)
        make -j $CORES
        make install
    GCC
    retries 5
    retry_delay 10
    creates '/opt/arm/armpl/gcc'
  end

  gcc_modulefile = "/opt/arm/armpl/#{armpl_version}/modulefiles/armpl/gcc-#{gcc_major_minor_version}"

  # gcc modulefile configuration
  template gcc_modulefile do
    source 'arm_pl/gcc_modulefile.erb'
    cookbook 'aws-parallelcluster-platform'
    user 'root'
    group 'root'
    mode '0755'
    variables(
      gcc_version: gcc_version
    )
  end

  # save ArmPL and gcc versions on the node environment so that they will be available
  # to dependencies (for instance, test code)
  # Complete versions are intentionally redundant.
  node.default['cluster']['armpl']['major_minor_version'] = new_resource.armpl_major_minor_version
  node.default['cluster']['armpl']['version'] = armpl_version
  node.default['cluster']['armpl']['gcc']['major_minor_version'] = gcc_major_minor_version
  node.default['cluster']['armpl']['gcc']['patch_version'] = new_resource.gcc_patch_version
  node.default['cluster']['armpl']['gcc']['version'] = gcc_version

  node_attributes "dump node attributes"
end

action_class do
  def modulefile_dir
    '/usr/share/Modules/modulefiles'
  end
end
