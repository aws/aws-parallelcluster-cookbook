#
# Cookbook Name:: nfs
# Recipe:: _sysctl
#
# Copyright 2011-2018, Eric G. Wolfe
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

# Related to https://bugzilla.redhat.com/show_bug.cgi?id=1413272
# Seems like this is also a bug on Debian 8, and Ubuntu 14.04
return unless (node['platform_family'] == 'rhel' && node['platform_version'].to_f >= 7.0 &&
              node['platform'] != 'amazon' && node['virtualization']['system'] != 'openvz') ||
              (node['platform_family'] == 'debian' && node['platform_version'].to_i == 8 ||
              node['platform_version'].to_i == 14)

sysctl_keys = %w(fs.nfs.nlm_tcpport fs.nfs.nlm_udpport)

if Chef::VERSION.to_f >= 14.0
  sysctl_keys.each do |key|
    sysctl key do
      value node['nfs']['port']['lockd']
      only_if { node['kernel']['modules'].include?('lockd') }
    end
  end
else
  sysctl_keys.each do |key|
    # Rendering sysctl key/value content here, to avoid
    # using the sysctl cookbook on Chef 13
    file "/etc/sysctl.d/99-chef-#{key}.conf" do
      content "#{key} = #{node['nfs']['port']['lockd']}"
      notifies :run, "execute[sysctl -p /etc/sysctl.d/99-chef-#{key}.conf]", :delayed
    end

    # Run the sysctl execute after the file has been rendered
    execute "sysctl -p /etc/sysctl.d/99-chef-#{key}.conf" do
      action :nothing
    end

    # Need to restart server service for static ports to activate
    service node['nfs']['service']['server'] do
      action :nothing
      subscribes :restart, "execute[sysctl -p /etc/sysctl.d/99-chef-#{key}.conf]", :delayed
    end
  end
end

service 'rpcbind' do
  action [:start, :enable]
  supports status: true
end
