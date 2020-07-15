#
# Cookbook Name:: nfs
# Recipe:: _common
#
# Copyright 2011-2014, Eric G. Wolfe
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

# Install package, dependent on platform
node['nfs']['packages'].each do |nfspkg|
  package nfspkg
end

# On FreeBSD, create the potentially missing configuration directory
directory ::File.dirname(node['nfs']['config']['server_template']) do
  mode 0o0755
  action :create
  only_if { node['platform_family'] == 'freebsd' }
end

client_service_list = node['nfs']['client-services']

# Configure NFS client components
node['nfs']['config']['client_templates'].each do |client_template|
  template client_template do
    mode 0o0644
    client_service_list.each do |component|
      notifies :restart, "service[#{component}]", :immediately
    end
  end
end

# Start NFS client components
client_service_list.each do |component|
  service component do
    service_name node['nfs']['service'][component]
    action [:start, :enable]
    supports status: true
  end
end
