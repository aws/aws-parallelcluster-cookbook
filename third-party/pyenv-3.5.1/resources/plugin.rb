#
# Cookbook:: pyenv
# Resource:: plugin
#
# Author:: Darwin D. Wu <darwinwu67@gmail.com>
#
# Copyright:: 2018, Darwin D. Wu
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
provides :pyenv_plugin

property :git_url,     String, required: true
property :git_ref,     String, default: 'master'
property :environment, Hash
property :user,        String

# https://github.com/pyenv/pyenv/wiki/Plugins
action :install do
  # If we pass in a username, we then install the plugin to the user's home_dir
  # See chef_pyenv_script_helpers.rb for root_path
  git "Install #{new_resource.name} plugin" do
    checkout_branch 'deploy'
    destination ::File.join(root_path, 'plugins', new_resource.name)
    repository  new_resource.git_url
    reference   new_resource.git_ref
    user        new_resource.user if new_resource.user
    action      :sync
    environment(new_resource.environment)
  end
end

action_class do
  include Chef::Pyenv::ScriptHelpers
end
