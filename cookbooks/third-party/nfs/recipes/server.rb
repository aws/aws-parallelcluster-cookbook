#
# Cookbook:: nfs
# Recipe:: server
#
# Copyright:: 2011-2014, Eric G. Wolfe
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

include_recipe 'nfs::_common'

# Install server components for Debian
package 'nfs-kernel-server' if platform_family?('debian')

# Configure nfs-server components
if node['nfs']['config']['client_templates'].include?(node['nfs']['config']['server_template'])
  r = resources(template: node['nfs']['config']['server_template'])
  r.notifies :restart, "service[#{node['nfs']['service']['server']}]"
else
  template node['nfs']['config']['server_template'] do
    source 'nfs.erb'
    mode '644'
    notifies :restart, "service[#{node['nfs']['service']['server']}]"
  end
end

# RHEL7 has some extra requirements per
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Storage_Administration_Guide/nfs-serverconfig.html#s2-nfs-nfs-firewall-config
include_recipe 'nfs::_sysctl'

# Start nfs-server components
service node['nfs']['service']['server'] do
  action [:start, :enable]
  supports status: true
end
