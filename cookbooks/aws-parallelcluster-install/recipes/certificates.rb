# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: certificates
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

directory '/opt/cinc/embedded/ssl/certs/' do
  owner "root"
  mode '0755'
  recursive true
end

# Prevent Chef from using outdated/distrusted CA certificates
# https://github.com/chef/chef/issues/12126
package 'ca-certificates' do
  action :purge
end
package 'ca-certificates' do
  action :install
end
execute 'Updating CA certificates...' do
  command 'update-ca-certificates --verbose --fresh'
end
link '/opt/cinc/embedded/ssl/certs/cacert.pem' do
  to '/etc/ssl/certs/ca-certificates.crt'
end

directory '/opt/parallelcluster/sources' do
  owner "root"
  mode '0755'
  recursive true
end

armpl_installer = "#{node['cluster']['sources_dir']}/"\
                  "arm-performance-libraries_#{node['cluster']['armpl']['version']}_#{node['cluster']['armpl']['platform']}_gcc-#{node['cluster']['armpl']['gcc']['major_minor_version']}.tar"
armpl_url = "https://#{node['cluster']['region']}-aws-parallelcluster.s3.#{node['cluster']['region']}.#{aws_domain}/#{node['cluster']['armpl']['url']}"

remote_file armpl_installer do
  source armpl_url
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?("/opt/arm/armpl/#{node['cluster']['armpl']['version']}") }
end
