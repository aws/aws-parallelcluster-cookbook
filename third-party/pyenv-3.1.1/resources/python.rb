#
# Cookbook:: pyenv
# Resource:: python
#
# Author:: Shane da Silva
# Author:: Darwin D. Wu <darwinwu67@gmail.com>
#
# Copyright:: 2014-2017, Shane da Silva
# Copyright:: 2017-2018, Darwin D. Wu
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
provides :pyenv_python

property :version,      String, name_property: true
property :version_file, String
property :user,         String
property :environment,  Hash
property :pyenv_action, String, default: 'install'
property :verbose,      [true, false], default: false

action :install do
  Chef::Log.fatal('Rubinius not supported by this cookbook') if new_resource.version =~ /rbx/

  install_start = Time.now

  Chef::Log.info("Building Python #{new_resource.version}, this could take a while...")

  command = %(pyenv #{new_resource.pyenv_action} #{new_resource.version} #{verbose})

  pyenv_script "#{command} #{which_pyenv}" do
    code        command
    user        new_resource.user        if new_resource.user
    environment new_resource.environment if new_resource.environment
    live_stream true                     if new_resource.verbose
    action      :run
  end unless python_installed?

  Chef::Log.info("#{new_resource} build time was #{(Time.now - install_start) / 60.0} minutes")
end

action :reinstall do
end

action_class do
  include Chef::Pyenv::ScriptHelpers

  def python_installed?
    if Array(new_resource.action).include?(:reinstall)
      false
    elsif ::File.directory?(::File.join(root_path, 'versions', new_resource.version))
      true
    end
  end

  def verbose
    return '-v' if new_resource.verbose
  end
end
