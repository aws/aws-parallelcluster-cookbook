#
# Cookbook:: pyenv
# Resource:: rehash
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
provides :pyenv_rehash

property :user, String

action :run do
  pyenv_script "pyenv rehash #{which_pyenv}" do
    code %(pyenv rehash)
    user new_resource.user if new_resource.user
    action :run
  end
end

action_class do
  include Chef::Pyenv::ScriptHelpers
end
