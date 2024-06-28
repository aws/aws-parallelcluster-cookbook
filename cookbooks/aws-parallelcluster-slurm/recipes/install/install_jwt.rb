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

jwt_version = '1.15.3'
jwt_tarball = "#{node['cluster']['sources_dir']}/libjwt-#{jwt_version}.tar.gz"

bash 'get jwt from s3' do
  user 'root'
  group 'root'
  cwd "#{node['cluster']['sources_dir']}"
  code <<-JWT
    set -e
    aws s3 cp #{node['cluster']['artifacts_build_url']}/jwt/v#{jwt_version}.tar.gz #{jwt_tarball} --region #{node['cluster']['region']}
    chmod 644 #{jwt_tarball}
    JWT
  retries 3
  retry_delay 5
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
