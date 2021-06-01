#
# Cookbook Name:: nfs
# Recipe:: undo
#
# Copyright 2012, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Stop nfs server components
service node['nfs']['service']['server'] do
  action [:stop, :disable]
end

service 'nfslock' do
  service_name node['nfs']['service']['lock']
  action [:stop, :disable]
end

# Stop nfs client components
service 'portmap' do
  service_name node['nfs']['service']['portmap']
  action [:stop, :disable]
end

# Remove package, dependent on platform
node['nfs']['packages'].each do |nfspkg|
  package nfspkg do
    action :remove
  end
end

# Remove server components for Debian
package 'nfs-kernel-server' do
  action :remove
  only_if { node['platform_family'] == 'debian' }
end

unless Chef::Config[:solo]
  ruby_block 'remove nfs::undo from run_list when there is a conflict' do
    block do
      node.run_list.remove('recipe[nfs::undo]')
    end
    only_if do
      node.run_list.include?('recipe[nfs::default]') || node.run_list.include?('recipe[nfs::client4]') ||
        node.run_list.include?('recipe[nfs::server]') || node.run_list.include?('recipe[nfs::server4]')
    end
  end
end
