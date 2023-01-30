# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_pmix
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

pmix_tarball = "#{node['cluster']['sources_dir']}/pmix-#{node['cluster']['pmix']['version']}.tar.gz"

remote_file pmix_tarball do
  source node['cluster']['pmix']['url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(pmix_tarball) }
end

ruby_block "Validate PMIx Tarball Checksum" do
  block do
    require 'digest'
    checksum = Digest::SHA256.file(pmix_tarball).hexdigest
    raise "Downloaded Tarball Checksum #{checksum} does not match expected checksum #{node['cluster']['pmix']['sha256']}" if checksum != node['cluster']['pmix']['sha256']
  end
end

bash 'Install PMIx' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-PMIX
    set -e
    tar xf #{pmix_tarball}
    cd pmix-#{node['cluster']['pmix']['version']}
    ./autogen.pl
    ./configure --prefix=/opt/pmix
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
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
