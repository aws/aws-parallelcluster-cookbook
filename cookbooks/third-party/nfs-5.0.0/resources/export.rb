#
# Cookbook:: nfs
# Resources:: export
#
# Copyright:: 2012, Riot Games
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

property :directory, String, name_property: true
property :network, [String, Array], required: true
property :writeable, [true, false], default: false
property :sync, [true, false], default: true
property :options, Array, default: ['root_squash']
property :anonuser, String
property :anongroup, String
property :unique, [true, false], default: false
property :fsid, String, default: 'root'

action :create do
  extend Nfs::Cookbook::Helpers

  ro_rw = new_resource.writeable ? 'rw' : 'ro'
  sync_async = new_resource.sync ? 'sync' : 'async'
  options = new_resource.options.join(',')
  options = ",#{options}" unless options.empty?
  options << ",anonuid=#{find_uid(new_resource.anonuser)}" if new_resource.anonuser
  options << ",anongid=#{find_gid(new_resource.anongroup)}" if new_resource.anongroup
  options << ",fsid=#{new_resource.fsid}" if platform_family?('fedora')

  if new_resource.network.is_a?(Array)
    host_permissions = new_resource.network.map { |net| net + "(#{ro_rw},#{sync_async}#{options})" }
    export_line = "#{new_resource.directory} #{host_permissions.join(' ')}\n"
  else
    export_line = "#{new_resource.directory} #{new_resource.network}(#{ro_rw},#{sync_async}#{options})\n"
  end

  execute 'exportfs' do
    command 'exportfs -ar'
    default_env true
    action :nothing
  end

  if ::File.zero?('/etc/exports') || !::File.exist?('/etc/exports')
    file '/etc/exports' do
      content export_line
      notifies :run, 'execute[exportfs]', :immediately
    end
  elsif new_resource.unique
    replace_or_add "export #{new_resource.name}" do
      path '/etc/exports'
      pattern "^#{new_resource.directory} "
      line export_line
      notifies :run, 'execute[exportfs]', :immediately
    end
  else
    append_if_no_line "export #{new_resource.name}" do
      path '/etc/exports'
      line export_line
      notifies :run, 'execute[exportfs]', :immediately
    end
  end
end
