#
# Cookbook:: selinux
# Resource:: state_debian
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

provides :selinux_state_debian
provides :selinux_state, platform_family: 'debian'

property :temporary, [true, false], default: false
property :policy, String, default: 'targeted'

action :enforcing do
  # check for temporary attribute. if temporary, and disabled log error
  execute 'selinux-enforcing' do
    not_if "getenforce | egrep -qx 'Disabled'"
    command 'setenforce 1'
  end if new_resource.temporary
  render_selinux_template('enforcing', new_resource.policy) unless new_resource.temporary
end

action :disabled do
  log 'Temporary changes to the running SELinux status is not possible when SELinux is disabled.' if new_resource.temporary
  render_selinux_template('disabled', new_resource.policy) unless new_resource.temporary
end

action :permissive do
  execute 'selinux-permissive' do
    not_if "getenforce | egrep -qx 'Disabled'"
    command 'setenforce 0'
  end if new_resource.temporary
  render_selinux_template('permissive', new_resource.policy) unless new_resource.temporary
end

action_class.class_eval do
  def getenforce
    @getenforce = shell_out('getenforce')
    @getenforce.stdout.chomp.downcase
  end

  def render_selinux_template(status, policy = 'targeted')
    template "#{status} selinux config" do
      path '/etc/selinux/config'
      source 'sysconfig/selinux.erb'
      cookbook 'selinux'
      variables(
        selinux: status,
        selinuxtype: policy
      )
    end
    Chef::Log.warn('It is advised to set the configuration to permissive to relabel the filesystem prior to enabling. Changes from disabled require a reboot. ') if getenforce == 'disabled' && status == 'enforcing'
    Chef::Log.info('Changes from disabled require a reboot. ') if getenforce == 'disabled' && status == 'permissive'
    Chef::Log.info('Disabling selinux requires a reboot.') if getenforce != 'disabled' && status == 'disabled'
    Chef::Log.warn('Supporting selinux on Debian platforms is deprecated. Support for this platform will be removed in the next major release.')
  end
end
