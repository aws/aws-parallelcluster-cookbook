#
# Cookbook:: selinux
# Resource:: user
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

unified_mode true

property :user, String,
          name_property: true,
          description: 'SELinux user'

property :level, String,
          description: 'MLS/MCS security level for the user'

property :range, String,
          description: 'MLS/MCS security range for the user'

property :roles, Array,
          description: 'SELinux roles for the user'

load_current_value do |new_resource|
  users = shell_out!('semanage user -l').stdout.split("\n")

  current_user = users.grep(/^#{Regexp.escape(new_resource.user)}\s+/) do |u|
    u.match(/^(?<user>[^\s]+)\s+(?<prefix>[^\s]+)\s+(?<level>[^\s]+)\s+(?<range>[^\s]+)\s+(?<roles>.*)$/)
    # match returns [<Match 'data'>] or [], shift converts that to <Match 'data'> or nil
  end.shift

  current_value_does_not_exist! unless current_user

  # Existing resources should maintain their current configuration unless otherwise specified
  new_resource.level ||= current_user[:level]
  new_resource.range ||= current_user[:range]
  new_resource.roles ||= current_user[:roles].to_s.split
  new_resource.roles = new_resource.roles.sort

  level current_user[:level]
  range current_user[:range]
  roles current_user[:roles].to_s.split.sort
end

action_class do
  def semanage_user_args
    args = ''

    args += " -L #{new_resource.level}" if new_resource.level
    args += " -r #{new_resource.range}" if new_resource.range
    args += " -R '#{new_resource.roles.join(' ')}'" unless new_resource.roles.to_a.empty?

    args
  end
end

action :manage do
  run_action(:add)
  run_action(:modify)
end

action :add do
  raise 'The roles property must be populated to create a new SELinux user' if new_resource.roles.to_a.empty?

  unless current_resource
    converge_if_changed do
      shell_out!("semanage user -a#{semanage_user_args} #{new_resource.user}")
    end
  end
end

action :modify do
  if current_resource
    converge_if_changed do
      shell_out!("semanage user -m#{semanage_user_args} #{new_resource.user}")
    end
  end
end

action :delete do
  if current_resource
    converge_by "deleting SELinux user #{new_resource.user}" do
      shell_out!("semanage user -d #{new_resource.user}")
    end
  end
end
