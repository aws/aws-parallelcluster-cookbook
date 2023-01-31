# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: install_jwt
#
# Copyright:: Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

jwt_version = node['cluster']['jwt']['version']
jwt_tarball = "#{node['cluster']['sources_dir']}/libjwt-#{jwt_version}.tar.gz"

remote_file jwt_tarball do
  source node['cluster']['jwt']['url']
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(jwt_tarball) }
end

ruby_block "Validate libjwt Tarball Checksum" do
  block do
    require 'digest'
    checksum = Digest::SHA1.file(jwt_tarball).hexdigest # nosemgrep
    raise "Downloaded Tarball Checksum #{checksum} does not match expected checksum #{node['cluster']['jwt']['sha1']}" if checksum != node['cluster']['jwt']['sha1']
  end
end

jwt_build_deps = value_for_platform(
  'ubuntu' => {
    'default' => 'libjansson-dev',
  },
  'default' => 'jansson-devel'
)

package jwt_build_deps do
  retries 3
  retry_delay 5
end

bash 'libjwt' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-LIBJWT
    set -e
    tar xf #{jwt_tarball}
    cd libjwt-#{jwt_version}
    autoreconf --force --install
    ./configure --prefix=/opt/libjwt
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    sudo make install
  LIBJWT
end
