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
    ./autogen.pl
    ./configure --prefix=/opt/pmix
    make
    make install
  PMIX
end

# Ensure directory containing PMIx shared library is part of the runtime
# loader's search path.
cookbook_file '/etc/ld.so.conf.d/pmix.conf' do
  source 'pmix/ld.so.conf.d/pmix.conf'
  owner 'root'
  group 'root'
  mode '0644'
end
execute 'ldconfig' do
  user 'root'
end
