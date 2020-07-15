#
# Cookbook:: selinux
# Recipe:: default
#
# Copyright:: 2017, Chef Software, Inc.
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

selinux_install 'selinux os prep'

selinux_state "SELinux #{node['selinux']['status'].capitalize}" do
  action node['selinux']['status'].downcase.to_sym
end

node['selinux']['booleans'].each do |boolean, value|
  value = SELinuxServiceHelpers.selinux_bool(value)
  next if value.nil?
  script "boolean_#{boolean}" do
    interpreter 'bash'
    code "setsebool -P #{boolean} #{value}"
    not_if "getsebool #{boolean} |egrep -q \" #{value}\"$"
  end
end
