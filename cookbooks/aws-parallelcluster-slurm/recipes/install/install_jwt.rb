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

jwt_version = '1.17.0'
jwt_url = "#{node['cluster']['artifacts_s3_url']}/dependencies/jwt/v#{jwt_version}.tar.gz"
jwt_tarball = "#{node['cluster']['sources_dir']}/libjwt-#{jwt_version}.tar.gz"
jwt_sha256 = '617778f9687682220abf9b7daacbe72bab7c2985479f8bee4db9648bd2440687'

remote_file jwt_tarball do
  source jwt_url
  mode '0644'
  retries 3
  retry_delay 5
  checksum jwt_sha256
  action :create_if_missing
end

jwt_dependencies 'Install jwt dependencies'

bash 'libjwt' do
  user 'root'
  group 'root'
  cwd Chef::Config[:file_cache_path]
  code <<-LIBJWT
    set -e
    tar xf #{jwt_tarball} --no-same-owner
    cd libjwt-#{jwt_version}
    autoreconf --force --install
    ./configure --prefix=/opt/libjwt
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    sudo make install
  LIBJWT
end unless redhat_on_docker?
