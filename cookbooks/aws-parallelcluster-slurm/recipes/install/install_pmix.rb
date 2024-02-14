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

# PMIx software
pmix_version = node['cluster']['pmix']['version']
pmix_url = "https://github.com/openpmix/openpmix/releases/download/v#{pmix_version}/pmix-#{pmix_version}.tar.gz"
pmix_sha256 = node['cluster']['pmix']['sha256']
pmix_tarball = "#{node['cluster']['sources_dir']}/pmix-#{pmix_version}.tar.gz"

remote_file pmix_tarball do
  source pmix_url
  mode '0644'
  retries 3
  retry_delay 5
  checksum pmix_sha256
  action :create_if_missing
end

bash 'Install PMIx' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-PMIX
    set -e
    tar xf #{pmix_tarball} --no-same-owner
    cd pmix-#{pmix_version}
    ./autogen.pl
    ./configure --prefix=/opt/pmix
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    make install
  PMIX
end unless redhat_on_docker?

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
