#
# Cookbook:: iptables
# Recipe:: default
#
# Copyright:: 2008-2019, Chef Software, Inc.
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
Chef::DSL::Recipe.include Iptables::Cookbook::Helpers
include_recipe 'iptables::_package'

Chef::Log.warn('The recipes inside iptables will be removed in the next major itteration (8.0.0), please change to resources provided by the iptables cookbook')

%w(iptables ip6tables).each do |ipt|
  file = if ipt == 'iptables'
           default_iptables_rules_file(:ipv4)
         else
           default_iptables_rules_file(:ipv6)
         end
  case node['platform_family']
  when 'debian'
    # debian based systems load iptables during the interface activation
    template "/etc/network/if-pre-up.d/#{ipt}_load" do
      source 'iptables_load.erb'
      mode '0755'
      variables(
        iptables_save_file: file,
        iptables_restore_binary: "/sbin/#{ipt}-restore"
      )
    end

    execute "reload #{ipt}" do
      command "/etc/network/if-pre-up.d/#{ipt}_load"
      subscribes :run, "template[#{file}]", :delayed
      action :nothing
    end
  when 'rhel', 'fedora', 'amazon'
    # iptables service exists only on RHEL based systems
    file "/etc/sysconfig/#{ipt}" do
      content '# Chef managed placeholder to allow iptables service to start'
      action :create_if_missing
    end

    template "/etc/sysconfig/#{ipt}-config" do
      source 'iptables-config.erb'
      mode '600'
      variables(
        config: node['iptables']["#{ipt}_sysconfig"]
      )
    end

    service ipt do
      supports status: true, start: true, stop: true, restart: true, reload: true
      subscribes :restart, "template[#{file}]", :delayed
      action [:enable, :start]
    end
  end
end
