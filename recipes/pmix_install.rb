# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: pmix_install
#
# Copyright 2013-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

return if node['conditions']['ami_bootstrapped']

# The versions of autoconf, automake, and libtool installable on CentOS 6
# via yum are too old to meet PMIx's requirements. Update them via the
# included recipe.
if node['platform'] == 'centos' && node['platform_version'].to_i == 6

  # Make directory for PMIx dependencies
  directory node['cfncluster']['pmix']['dependencies_dir'] do
    user 'root'
    group 'root'
    mode '0755'
  end

  # Import GNU public key so the individual package signatures can be verified
  gnu_public_key_path = "#{node['cfncluster']['sources_dir']}/gnu-keyring.gpg"
  remote_file gnu_public_key_path do
    source 'https://ftp.gnu.org/gnu/gnu-keyring.gpg'
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(gnu_public_key_path) }
  end
  execute "gpg --import #{gnu_public_key_path}" do
    user 'root'
  end

  %w[autoconf automake libtool].each do |package_name|
    # Download the newer version of the package
    package_tarball = "#{node['cfncluster']['sources_dir']}/#{package_name}-#{node['cfncluster']['pmix'][package_name]['version']}.tar.xz"
    remote_file package_tarball do
      source node['cfncluster']['pmix'][package_name]['tarball-url']
      mode '0644'
      retries 3
      retry_delay 5
      not_if { ::File.exist?(package_tarball) }
    end

    # Downloaded the corresponding signature file
    signature_file = "#{package_tarball}.sig"
    remote_file signature_file do
      source node['cfncluster']['pmix'][package_name]['signature-url']
      mode '0644'
      retries 3
      retry_delay 5
      not_if { ::File.exist?(signature_file) }
    end

    # Make sure the signature matches one of the identities in the GNU keyring
    execute "gpg --verify #{signature_file} #{package_tarball}" do
      user 'root'
    end

    # Build and install the software
    bash "Install #{package_name}" do
      user 'root'
      group 'root'
      cwd Chef::Config[:file_cache_path]
      code <<-PMIX
        set -e
        tar xf #{package_tarball}
        cd #{package_name}-#{node['cfncluster']['pmix'][package_name]['version']}
        export PATH=#{node['cfncluster']['pmix']['dependencies_dir']}/bin:$PATH
        ./configure --prefix=#{node['cfncluster']['pmix']['dependencies_dir']}
        make
        make install
      PMIX
    end
  end

  # The version of libevent-devel installable on CentOS 6 via yum is too old to
  # meet PMIx's requirements. Install it from source.
  libevent_tarball = "#{node['cfncluster']['sources_dir']}/libevent-#{node['cfncluster']['pmix']['libevent']['version']}.tar.gz"
  remote_file libevent_tarball do
    source node['cfncluster']['pmix']['libevent']['tarball-url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(libevent_tarball) }
  end

  # Download signature file
  signature_file = "#{libevent_tarball}.sig"
  remote_file signature_file do
    source node['cfncluster']['pmix']['libevent']['signature-url']
    mode '0644'
    retries 3
    retry_delay 5
    not_if { ::File.exist?(signature_file) }
  end

  # Import public key ID expected in signature file just downloaded.
  execute 'gpg --recv-keys 8EF8686D' do
    user 'root'
  end

  # Verify tarball signature.
  execute "gpg --verify #{signature_file} #{libevent_tarball}" do
    user 'root'
  end

  # Build and install libevent
  bash "Install libevent" do
    user 'root'
    group 'root'
    cwd Chef::Config[:file_cache_path]
    code <<-PMIX
      set -e
      tar xf #{libevent_tarball}
      cd libevent-#{node['cfncluster']['pmix']['libevent']['version']}-stable
      # Set path such that updated autoconf, automake, and libtool are used
      export PATH=#{node['cfncluster']['pmix']['dependencies_dir']}/bin:$PATH
      ./configure --prefix=#{node['cfncluster']['pmix']['dependencies_dir']}
      make
      make install
    PMIX
  end

  # Set variable passed to configure when building PMIx in order to tell it where libevent is
  pmix_config_flags = "--with-libevent=#{node['cfncluster']['pmix']['dependencies_dir']}"
else
  pmix_config_flags = ''
end

pmix_tarball = "#{node['cfncluster']['sources_dir']}/pmix-#{node['cfncluster']['pmix']['version']}.tar.gz"

remote_file pmix_tarball do
  source node['cfncluster']['pmix']['url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(pmix_tarball) }
end

ruby_block "Validate PMIx Tarball Checksum" do
  block do
    require 'digest'
    checksum = Digest::SHA1.file(pmix_tarball).hexdigest
    raise "Downloaded Tarball Checksum #{checksum} does not match expected checksum #{node['cfncluster']['pmix']['sha1']}" if checksum != node['cfncluster']['pmix']['sha1']
  end
end

bash 'Install PMIx' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-PMIX
    set -e
    tar xf #{pmix_tarball}
    cd pmix-#{node['cfncluster']['pmix']['version']}
    # Set path such that updated autoconf, automake, and libtool are used
    export PATH=#{node['cfncluster']['pmix']['dependencies_dir']}/bin:$PATH
    ./autogen.pl
    ./configure #{pmix_config_flags} --prefix=/usr
    make
    make install
  PMIX
end
