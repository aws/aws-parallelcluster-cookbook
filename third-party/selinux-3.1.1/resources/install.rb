#
# Cookbook:: selinux
# Resource:: install
#
# Copyright:: 2016-2019, Chef Software, Inc.
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

action :install do
  package package_list

  directory '/etc/selinux' do
    owner 'root'
    group 'root'
    mode '0755'
    action :create
  end
end

action_class do
  #
  # The complete list of package
  #
  # @return [Array<string>]
  #
  def package_list
    list = %w(policycoreutils selinux-policy selinux-policy-targeted libselinux-utils)
    list << 'mcstrans' if node['selinux']['install_mcstrans_package']
    list
  end
end
