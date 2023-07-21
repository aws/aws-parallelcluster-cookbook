#
# Cookbook:: pyenv
# Resource:: script
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

provides :pyenv_script

property :pyenv_version, String
property :code,          String
property :creates,       String
property :cwd,           String
property :environment,   Hash
property :group,         String
property :path,          Array
property :returns,       Array, default: [0]
property :timeout,       Integer
property :user,          String
property :umask,         [String, Integer]
property :live_stream,   [true, false], default: false

action :run do
  bash new_resource.name do
    code        script_code
    creates     new_resource.creates if new_resource.creates
    cwd         new_resource.cwd     if new_resource.cwd
    user        new_resource.user    if new_resource.user
    group       new_resource.group   if new_resource.group
    returns     new_resource.returns if new_resource.returns
    timeout     new_resource.timeout if new_resource.timeout
    umask       new_resource.umask   if new_resource.umask
    flags       '-e'
    environment(script_environment)
    live_stream new_resource.live_stream
  end
end

action_class do
  include Chef::Pyenv::ScriptHelpers
end
