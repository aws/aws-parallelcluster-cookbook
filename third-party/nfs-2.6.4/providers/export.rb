#
# Cookbook Name:: nfs
# Providers:: export
#
# Copyright 2012, Riot Games
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
use_inline_resources

action :create do
  sub_run_context = @run_context.dup
  sub_run_context.resource_collection = Chef::ResourceCollection.new

  begin
    original_run_context = @run_context
    @run_context = sub_run_context

    ro_rw = new_resource.writeable ? 'rw' : 'ro'
    sync_async = new_resource.sync ? 'sync' : 'async'
    options = new_resource.options.join(',')
    options = ",#{options}" unless options.empty?
    options << ",anonuid=#{find_uid(new_resource.anonuser)}" if new_resource.anonuser
    options << ",anongid=#{find_gid(new_resource.anongroup)}" if new_resource.anongroup

    if new_resource.network.is_a?(Array)
      host_permissions = new_resource.network.map { |net| net + "(#{ro_rw},#{sync_async}#{options})" }
      export_line = "#{new_resource.directory} #{host_permissions.join(' ')}\n"
    else
      export_line = "#{new_resource.directory} #{new_resource.network}(#{ro_rw},#{sync_async}#{options})\n"
    end

    execute 'exportfs' do
      command 'exportfs -ar'
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
  ensure
    @run_context = original_run_context
  end

  # converge
  begin
    Chef::Runner.new(sub_run_context).converge
  ensure
    if sub_run_context.resource_collection.any?(&:updated?)
      new_resource.updated_by_last_action(true)
    end
  end
end

private

# Finds the UID for the given user name
#
# @param [String] username
# @return
def find_uid(username)
  uid = nil
  Etc.passwd do |entry|
    if entry.name == username
      uid = entry.uid
      break
    end
  end
  uid
end

# Finds the GID for the given group name
#
# @param [String] groupname
# @return [Integer] the matching GID or nil
def find_gid(groupname)
  gid = nil
  Etc.group do |entry|
    if entry.name == groupname
      gid = entry.gid
      break
    end
  end
  gid
end
