#
# Cookbook:: pyenv
# Resource:: global
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

# Check for the user or system global verison
# If we pass in a user check that users global

provides :pyenv_global

property :pyenv_version, String, name_property: true
property :user,          String
property :root_path,     String, default: lazy {
  if user
    node.run_state['root_path'][user]
  else
    node.run_state['root_path']['system']
  end
}

# This sets the Global pyenv version
# e.g. "pyenv global" should return the version we set

action :create do
  pyenv_script "globals #{which_pyenv}" do
    code "pyenv global #{new_resource.pyenv_version}"
    user new_resource.user if new_resource.user
    action :run
    not_if { current_global_version_correct? }
  end
end

action_class do
  include Chef::Pyenv::ScriptHelpers

  def current_global_version_correct?
    current_global_version == new_resource.pyenv_version
  end

  def current_global_version
    version_file = ::File.join(new_resource.root_path, 'version')

    ::File.exist?(version_file) && ::IO.read(version_file).chomp
  end
end
