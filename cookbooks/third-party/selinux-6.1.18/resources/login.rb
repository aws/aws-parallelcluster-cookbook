#
# Cookbook:: selinux
# Resource:: login
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

property :login, String,
          name_property: true,
          description: 'OS user login'

property :user, String,
          description: 'SELinux user'

property :range, String,
          description: 'MLS/MCS security range for the login'

load_current_value do |new_resource|
  logins = shell_out!('semanage login -l').stdout.split("\n")

  current_login = logins.grep(/^#{Regexp.escape(new_resource.login)}\s+/) do |l|
    l.match(/^(?<login>[^\s]+)\s+(?<user>[^\s]+)\s+(?<range>[^\s]+)/)
    # match returns [<Match 'data'>] or [], shift converts that to <Match 'data'> or nil
  end.shift

  current_value_does_not_exist! unless current_login

  # Existing resources should maintain their current configuration unless otherwise specified
  new_resource.user ||= current_login[:user]
  new_resource.range ||= current_login[:range]

  user current_login[:user]
  range current_login[:range]
end

action_class do
  def semanage_login_args
    args = ''

    args += " -s #{new_resource.user}" if new_resource.user
    args += " -r #{new_resource.range}" if new_resource.range

    args
  end
end

action :manage do
  run_action(:add)
  run_action(:modify)
end

action :add do
  raise 'The user property must be populated to create a new SELinux login' unless new_resource.user

  unless current_resource
    converge_if_changed do
      shell_out!("semanage login -a#{semanage_login_args} #{new_resource.login}")
    end
  end
end

action :modify do
  if current_resource
    converge_if_changed do
      shell_out!("semanage login -m#{semanage_login_args} #{new_resource.login}")
    end
  end
end

action :delete do
  if current_resource
    converge_by "deleting SELinux login #{new_resource.login}" do
      shell_out!("semanage login -d #{new_resource.login}")
    end
  end
end
