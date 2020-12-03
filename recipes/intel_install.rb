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

return unless node['conditions']['intel_hpc_platform_supported'] && node['cfncluster']['enable_intel_hpc_platform'] == 'true'

if node['platform'] == 'centos' && node['platform_version'].to_i == 8
  # Enforce keepcache=True for dnf, else downloaded packages will be removed after any successful install
  replace_or_add "configure dnf caching" do
    path "/etc/dnf/dnf.conf"
    pattern "keepcache.*"
    line "keepcache=True"
  end
end

def download_intel_hpc_pkg_from_s3(pkg_subdir_key, package_basename, dest_path)
  # S3 key prefix under which all packages to be downloaded reside
  s3_base_url = "https://#{node['cfncluster']['cfn_region']}-aws-parallelcluster.s3.#{node['cfncluster']['cfn_region']}.#{aws_domain}"
  intel_hpc_packages_dir_s3_url = "#{s3_base_url}/archives/IntelHPC/#{node['cfncluster']['intelhpc']['platform_name']}"
  remote_file dest_path do
    source "#{intel_hpc_packages_dir_s3_url}/#{pkg_subdir_key}/#{package_basename}"
    mode '0744'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(dest_path) }
  end
end

# Install non-intel dependencies first
intel_hpc_base_dependencies = value_for_platform(
  'centos' => {
    '~>8' => %w[tcsh libnsl nss-pam-ldapd nss_nis nscd],
    '~>7' => %w[tcsh compat-libstdc++-33 nscd nss-pam-ldapd openssl098e]
  }
)
package intel_hpc_base_dependencies
intel_hpc_spec_rpms_dir = '/opt/intel/rpms'

case node['cfncluster']['cfn_node_type']
when 'MasterServer'

  # Intel HPC Platform
  directory intel_hpc_spec_rpms_dir do
    recursive true
  end
  node['cfncluster']['intelhpc']['packages'].each do |package_name|
    # Download intel-hpc-platform rpms to shared /opt/intel/rpms to avoid repetitive download from all nodes
    # Packages must be downloaded individually because S3 doesn't permit wget'ing entire directories, nor does
    # it permit recursive copies of 'directories' (even those containing only public artifacts).
    # It's installed on every node (as opposed to just the head node) because the resulting RPMs install
    # software to /etc which is not exported to the computes as /opt/intel is.
    package_basename = "#{package_name}-#{node['cfncluster']['intelhpc']['version']}.#{node['cfncluster']['intelhpc']['platform_name']}.x86_64.rpm"
    download_intel_hpc_pkg_from_s3('hpc_platform_spec', package_basename, "#{intel_hpc_spec_rpms_dir}/#{package_basename}")
  end

  # Install Intel Parallel Studio XE Runtime, see
  # https://software.intel.com/content/www/us/en/develop/articles/installing-intel-parallel-studio-xe-runtime-2020-using-yum-repository.html
  intel_psxe_rpms_dir = "#{node['cfncluster']['sources_dir']}/intel/psxe"
  directory intel_psxe_rpms_dir do
    recursive true
  end

  # Download non-architecture-specific packages.
  node['cfncluster']['psxe']['noarch_packages'].each do |psxe_noarch_package|
    package_basename = "#{psxe_noarch_package}-#{node['cfncluster']['psxe']['version']}.noarch.rpm"
    download_intel_hpc_pkg_from_s3('psxe', package_basename, "#{intel_psxe_rpms_dir}/#{package_basename}")
  end

  # Download PSXE runtime packages and dependencies for 32- and 64-bit Intel compatible processors
  %w[i486 x86_64].each do |intel_architecture|
    # Download main package
    package_basename = "intel-psxe-runtime-#{node['cfncluster']['psxe']['version']}.#{intel_architecture}.rpm"
    download_intel_hpc_pkg_from_s3('psxe', package_basename, "#{intel_psxe_rpms_dir}/#{package_basename}")
    # Download dependencies
    node['cfncluster']['psxe']['archful_packages'][intel_architecture].each do |psxe_archful_package|
      num_bits_for_arch = if intel_architecture == 'i486'
                            '32'
                          else
                            '64'
                          end
      package_basename = "#{psxe_archful_package}-#{num_bits_for_arch}bit-#{node['cfncluster']['psxe']['version']}.#{intel_architecture}.rpm"
      download_intel_hpc_pkg_from_s3('psxe', package_basename, "#{intel_psxe_rpms_dir}/#{package_basename}")
    end
  end

  # Install all downloaded PSXE packages
  bash "install PSXE packages" do
    cwd node['cfncluster']['sources_dir']
    code <<-INTEL
      set -e
      yum makecache -y && yum install --cacheonly -y #{intel_psxe_rpms_dir}/*
    INTEL
  end

  # Intel optimized versions of python
  %w[2 3].each do |python_version|
    package_version = node['cfncluster']["intelpython#{python_version}"]['version']
    package_basename = "intelpython#{python_version}-#{package_version}.x86_64.rpm"
    dest_path = "#{node['cfncluster']['sources_dir']}/#{package_basename}"
    download_intel_hpc_pkg_from_s3("intelpython#{python_version}", package_basename, dest_path)
    bash "install intelpython#{python_version}" do
      cwd node['cfncluster']['sources_dir']
      code <<-INTEL
        set -e
        yum makecache -y && yum install --cacheonly -y #{dest_path}
      INTEL
      not_if { ::File.exist?("/opt/intel/intelpython#{python_version}") }
    end
  end
end

# Installs intel-hpc-platform rpms
# Install from /opt/intel/rpms, with --cacheonly option
# If --cacheonly is not specified, cached packages in /opt/intel/rpms might be removed if keepcache=False
# This rpm installs a file /etc/intel-hpc-platform-release that contains the INTEL_HPC_PLATFORM_VERSION
bash "install intel hpc platform" do
  cwd node['cfncluster']['sources_dir']
  code <<-INTEL
    set -e
    yum makecache -y && yum install --cacheonly -y #{intel_hpc_spec_rpms_dir}/*
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

# Intel optimized math kernel library
create_modulefile "#{node['cfncluster']['modulefile_dir']}/intelmkl" do
  source_path "/opt/intel/psxe_runtime/linux/mkl/bin/mklvars.sh"
  modulefile node['cfncluster']['psxe']['version']
end

# Intel psxe
create_modulefile "#{node['cfncluster']['modulefile_dir']}/intelpsxe" do
  source_path "/opt/intel/psxe_runtime/linux/bin/psxevars.sh"
  modulefile node['cfncluster']['psxe']['version']
end
