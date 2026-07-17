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

include_recipe 'iptables::_package'

Chef::Log.warn('The recipes inside iptables will be removed in the next major itteration (8.0.0), please change to resources provided by the iptables cookbook')

%w(iptables ip6tables).each do |ipt|
  service ipt do
    action [:disable, :stop]
    delayed_action :stop
    supports status: true, start: true, stop: true, restart: true
    only_if { platform_family?('rhel', 'fedora', 'amazon') }
  end

  ["/etc/sysconfig/#{ipt}", "/etc/sysconfig/#{ipt}.fallback"].each do |f|
    file f do
      content '# iptables rules files cleared by chef via iptables::disabled'
      only_if { platform_family?('rhel', 'fedora', 'amazon') }
      notifies :run, "execute[flush #{ipt}]", :immediately
    end
  end

  # Flush and delete iptables rules
  execute "flush #{ipt}" do
    command "#{ipt} -F"
    action :nothing
  end
end
