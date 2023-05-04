#
# Cookbook:: selinux
# Resource:: install
#
# Copyright:: 2016-2022, Chef Software, Inc.
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

unified_mode true

include SELinux::Cookbook::InstallHelpers

property :packages, [String, Array],
          default: lazy { default_install_packages },
          description: 'SELinux packages for system'

action_class do
  def do_package_action(action)
    # friendly message for unsupported platforms
    raise "The platform #{node['platform']} is not currently supported by the `selinux_install` resource. Please file an issue at https://github.com/sous-chefs/selinux/issues/new with details on the platform this cookbook is running on." if new_resource.packages.nil?

    package 'selinux' do
      package_name new_resource.packages
      action action
    end
  end
end

action :install do
  do_package_action(action)

  directory '/etc/selinux' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end

%i(upgrade remove).each do |a|
  action a do
    do_package_action(a)
  end
end
