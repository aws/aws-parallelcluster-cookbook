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

jwt_version = '1.12.0'
jwt_url = "https://github.com/benmcollins/libjwt/archive/refs/tags/v#{jwt_version}.tar.gz"
jwt_tarball = "#{node['cluster']['sources_dir']}/libjwt-#{jwt_version}.tar.gz"
jwt_sha256 = 'eaf5d8b31d867c02dde767efa2cf494840885a415a3c9a62680bf870a4511bee'

remote_file jwt_tarball do
  source jwt_url
  mode '0644'
  retries 3
  retry_delay 5
  action :create_if_missing
end

ruby_block "Validate libjwt Tarball Checksum" do
  block do
    require 'digest'
    checksum = Digest::SHA256.file(jwt_tarball).hexdigest
    raise "Downloaded Tarball Checksum #{checksum} does not match expected checksum #{jwt_sha256}" if checksum != jwt_sha256
  end
end

jwt_dependencies 'Install jwt dependencies'

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
end unless redhat_ubi?
