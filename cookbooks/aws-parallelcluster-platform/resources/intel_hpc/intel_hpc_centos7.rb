# frozen_string_literal: true

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

provides :intel_hpc, platform: 'centos' do |node|
  node['platform_version'].to_i == 7
end

unified_mode true
default_action :setup

property :sources_dir, String
property :dependencies, default: %w(compat-libstdc++-33 nscd nss-pam-ldapd openssl098e
                                    at avahi-libs cups-client cups-libs dejavu-fonts-common dejavu-sans-fonts ed
                                    fontconfig fontpackages-filesystem freetype gettext gettext-libs hwdata libcroco
                                    libICE libgomp libSM libX11 libX11-common libXau
                                    libXcursor libXdamage libXext libXfixes libXft libXi libXinerama libXmu libXp
                                    libXrandr libXrender libXt libXtst libXxf86vm libdrm libglvnd libglvnd-glx
                                    libjpeg-turbo libpciaccess libpipeline libpng libpng12 libunistring libxcb
                                    libxshmfence m4 mailx man-db mariadb-libs mesa-libGL
                                    mesa-libGLU mesa-libglapi patch pax perl perl-Carp perl-Data-Dumper perl-Encode
                                    perl-Exporter perl-File-Path perl-File-Temp perl-Filter perl-Getopt-Long perl-HTTP-Tiny
                                    perl-PathTools perl-Pod-Escapes perl-Pod-Perldoc perl-Pod-Simple perl-Pod-Usage
                                    perl-Scalar-List-Utils perl-Socket perl-Storable perl-Text-ParseWords perl-Time-HiRes
                                    perl-Time-Local perl-constant perl-libs perl-macros perl-parent perl-podlators
                                    perl-threads perl-threads-shared postfix psmisc redhat-lsb-core redhat-lsb-submod-security
                                    spax tcl tcsh time)

action :setup do
  return unless intel_hpc_supported?

  node.default['cluster']['intelhpc']['dependencies'] = new_resource.dependencies
  node_attributes 'Save properties for InSpec tests'

  new_resource.sources_dir = new_resource.sources_dir || node['cluster']['sources_dir']

  directory new_resource.sources_dir do
    recursive true
  end

  bash 'download dependencies Intel HPC platform' do
    code <<-INTEL
      yum install --downloadonly #{new_resource.dependencies.join(' ')} --downloaddir=#{new_resource.sources_dir}
      yum makecache -y
    INTEL
  end
end

property :region, String
property :aws_domain, String
property :node_type, String
property :packages, default: %w(intel-hpc-platform-core-intel-runtime-advisory intel-hpc-platform-compat-hpc-advisory
                                intel-hpc-platform-core intel-hpc-platform-core-advisory intel-hpc-platform-hpc-cluster
                                intel-hpc-platform-compat-hpc intel-hpc-platform-core-intel-runtime)
property :version, default: '2018.0-7'

property :psxe_noarch_packages, default: %w(intel-tbb-common-runtime intel-mkl-common-runtime intel-psxe-common-runtime
                                            intel-ipp-common-runtime intel-ifort-common-runtime intel-icc-common-runtime
                                            intel-daal-common-runtime intel-comp-common-runtime)
property :psxe_version, default: '2020.4-17'
property :psxe_archful_packages_i486, default: %w(intel-tbb-runtime intel-tbb-libs-runtime intel-comp-runtime
                                                            intel-daal-runtime intel-icc-runtime intel-ifort-runtime
                                                            intel-ipp-runtime intel-mkl-runtime intel-openmp-runtime)
property :psxe_archful_packages_x86_64, default: %w(intel-mpi-runtime)
property :intelpython_version, default: {
  '2' => '2019.4-088',
  '3' => '2020.2-902',
}

action :configure do
  return unless intel_hpc_supported? && node['cluster']['enable_intel_hpc_platform'] == 'true'

  node.default['cluster']['psxe']['version'] = new_resource.psxe_version
  node.default['cluster']['psxe']['noarch_packages'] = new_resource.psxe_noarch_packages
  node.default['cluster']['intelhpc']['dependencies'] = new_resource.dependencies
  node.default['cluster']['intelhpc']['packages'] = new_resource.packages
  node.default['cluster']['intelhpc']['version'] = new_resource.version
  node.default['cluster']['psxe']['archful_packages']['i486'] = new_resource.psxe_archful_packages_i486
  node.default['cluster']['psxe']['archful_packages']['x86_64'] = new_resource.psxe_archful_packages_i486 + new_resource.psxe_archful_packages_x86_64
  node.default['cluster']["intelpython2"]['version'] = new_resource.intelpython_version['2']
  node.default['cluster']["intelpython3"]['version'] = new_resource.intelpython_version['3']
  node_attributes 'Save properties for InSpec tests'

  return if arm_instance? || node['cluster']['enable_intel_hpc_platform'].to_s != 'true'

  new_resource.region = new_resource.region || node['cluster']['region']
  new_resource.aws_domain = new_resource.aws_domain || aws_domain
  new_resource.sources_dir = new_resource.sources_dir || node['cluster']['sources_dir']
  new_resource.node_type = new_resource.node_type || node['cluster']['node_type']

  # Install non-intel dependencies first
  bash "install non-intel dependencies" do
    cwd new_resource.sources_dir
    code <<-INTEL
    set -e
    yum localinstall --cacheonly -y `ls #{new_resource.dependencies.map { |name| "#{name}*.rpm" }.join(' ')}`
    INTEL
  end

  intel_hpc_spec_rpms_dir = '/opt/intel/rpms'
  s3_base_url = "https://#{new_resource.region}-aws-parallelcluster.s3.#{new_resource.region}.#{new_resource.aws_domain}"
  intel_hpc_packages_dir_s3_url = "#{s3_base_url}/archives/IntelHPC/el7"

  case new_resource.node_type
  when 'HeadNode'

    # Intel HPC Platform
    directory intel_hpc_spec_rpms_dir do
      recursive true
    end
    new_resource.packages.each do |package_name|
      # Download intel-hpc-platform rpms to shared /opt/intel/rpms to avoid repetitive download from all nodes
      # Packages must be downloaded individually because S3 doesn't permit wget'ing entire directories, nor does
      # it permit recursive copies of 'directories' (even those containing only public artifacts).
      # It's installed on every node (as opposed to just the head node) because the resulting RPMs install
      # software to /etc which is not exported to the computes as /opt/intel is.
      package_basename = "#{package_name}-#{new_resource.version}.el7.x86_64.rpm"

      remote_file "#{intel_hpc_spec_rpms_dir}/#{package_basename}" do
        source "#{intel_hpc_packages_dir_s3_url}/hpc_platform_spec/#{package_basename}"
        mode '0744'
        retries 3
        retry_delay 5
        action :create_if_missing
      end
    end

    # Install Intel Parallel Studio XE Runtime, see
    # https://software.intel.com/content/www/us/en/develop/articles/installing-intel-parallel-studio-xe-runtime-2020-using-yum-repository.html
    intel_psxe_rpms_dir = "#{new_resource.sources_dir}/intel/psxe"
    directory intel_psxe_rpms_dir do
      recursive true
    end

    # Download non-architecture-specific packages.
    new_resource.psxe_noarch_packages.each do |psxe_noarch_package|
      package_basename = "#{psxe_noarch_package}-#{new_resource.psxe_version}.noarch.rpm"
      remote_file "#{intel_psxe_rpms_dir}/#{package_basename}" do
        source "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}"
        mode '0744'
        retries 3
        retry_delay 5
        action :create_if_missing
      end
    end

    archful_packages = {
      'i486' => new_resource.psxe_archful_packages_i486,
      'x86_64' => new_resource.psxe_archful_packages_i486 + new_resource.psxe_archful_packages_x86_64,
    }
    # Download PSXE runtime packages and dependencies for 32- and 64-bit Intel compatible processors
    %w(i486 x86_64).each do |intel_architecture|
      # Download main package
      package_basename = "intel-psxe-runtime-#{new_resource.psxe_version}.#{intel_architecture}.rpm"
      remote_file "#{intel_psxe_rpms_dir}/#{package_basename}" do
        source "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}"
        mode '0744'
        retries 3
        retry_delay 5
        action :create_if_missing
      end
      # Download dependencies
      archful_packages[intel_architecture].each do |psxe_archful_package|
        num_bits_for_arch = if intel_architecture == 'i486'
                              '32'
                            else
                              '64'
                            end
        package_basename = "#{psxe_archful_package}-#{num_bits_for_arch}bit-#{new_resource.psxe_version}.#{intel_architecture}.rpm"
        remote_file "#{intel_psxe_rpms_dir}/#{package_basename}" do
          source "#{intel_hpc_packages_dir_s3_url}/psxe/#{package_basename}"
          mode '0744'
          retries 3
          retry_delay 5
          action :create_if_missing
        end
      end
    end

    # Install all downloaded PSXE packages
    bash "install PSXE packages" do
      cwd new_resource.sources_dir
      code <<-INTEL
      set -e
      yum localinstall --cacheonly -y #{intel_psxe_rpms_dir}/*
      INTEL
    end

    # Intel optimized versions of python
    %w(2 3).each do |python_version|
      package_version = new_resource.intelpython_version[python_version]
      package_basename = "intelpython#{python_version}-#{package_version}.x86_64.rpm"
      dest_path = "#{new_resource.sources_dir}/#{package_basename}"
      remote_file dest_path do
        source "#{intel_hpc_packages_dir_s3_url}/intelpython#{python_version}/#{package_basename}"
        mode '0744'
        retries 3
        retry_delay 5
        action :create_if_missing
      end
      bash "install intelpython#{python_version}" do
        cwd new_resource.sources_dir
        code <<-INTEL
        set -e
        yum localinstall --cacheonly -y #{dest_path}
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
    cwd new_resource.sources_dir
    code <<-INTEL
    set -e
    yum localinstall --cacheonly -y #{intel_hpc_spec_rpms_dir}/*
    INTEL
    creates '/etc/intel-hpc-platform-release'
  end

  # create intelpython module directory
  directory "#{modulefile_dir}/intelpython" do
    recursive true
  end

  cookbook_file 'intelpython2_modulefile' do
    source 'intel/intelpython2_modulefile'
    cookbook 'aws-parallelcluster-platform'
    path "#{modulefile_dir}/intelpython/2"
    user 'root'
    group 'root'
    mode '0755'
  end

  cookbook_file 'intelpython3_modulefile' do
    source 'intel/intelpython3_modulefile'
    cookbook 'aws-parallelcluster-platform'
    path "#{modulefile_dir}/intelpython/3"
    user 'root'
    group 'root'
    mode '0755'
  end

  # Intel optimized math kernel library
  create_modulefile "#{modulefile_dir}/intelmkl" do
    source_path "/opt/intel/psxe_runtime/linux/mkl/bin/mklvars.sh"
    modulefile new_resource.psxe_version
    cookbook 'aws-parallelcluster-platform'
  end

  # Intel psxe
  create_modulefile "#{modulefile_dir}/intelpsxe" do
    source_path "/opt/intel/psxe_runtime/linux/bin/psxevars.sh"
    modulefile new_resource.psxe_version
  end
end

def modulefile_dir
  '/usr/share/Modules/modulefiles'
end

def intel_hpc_supported?
  !arm_instance?
end
