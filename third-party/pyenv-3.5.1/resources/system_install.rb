#
# Cookbook:: pyenv
# Resource:: system_install
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

provides :pyenv_system_install

property :git_url,       String, default: node['pyenv']['git_url']
property :git_ref,       String, default: node['pyenv']['git_ref']
property :global_prefix, String, default: '/usr/local/pyenv'
property :environment,   Hash
property :update_pyenv,  [true, false], default: true

action :install do
  node.run_state['sous-chefs'] ||= {}
  node.run_state['sous-chefs']['pyenv'] ||= {}
  node.run_state['sous-chefs']['pyenv']['root_path'] ||= {}

  node.run_state['sous-chefs']['pyenv']['root_path']['system'] = new_resource.global_prefix

  apt_update 'update'
  build_essential 'build packages'
  package node['pyenv']['prerequisites']

  directory '/etc/profile.d' do
    owner 'root'
    mode '0755'
  end

  template '/etc/profile.d/pyenv.sh' do
    cookbook 'pyenv'
    source   'pyenv.sh'
    owner    'root'
    mode     '0755'
    variables(global_prefix: new_resource.global_prefix)
  end

  git new_resource.global_prefix do
    checkout_branch 'deploy'
    repository new_resource.git_url
    reference  new_resource.git_ref
    action     :checkout if new_resource.update_pyenv == false
    environment(new_resource.environment)

    notifies :run, 'ruby_block[Add pyenv to PATH]', :immediately
    notifies :run, 'bash[Initialize system pyenv]', :immediately
  end

  directory "#{new_resource.global_prefix}/plugins" do
    owner 'root'
    mode  '0755'
  end

  # Initialize pyenv
  ruby_block 'Add pyenv to PATH' do
    block do
      ENV['PATH'] = "#{new_resource.global_prefix}/shims:#{new_resource.global_prefix}/bin:#{ENV['PATH']}"
    end
    action :nothing
  end

  bash 'Initialize system pyenv' do
    code %(PATH="#{new_resource.global_prefix}/bin:$PATH" pyenv init -)
    environment('PYENV_ROOT' => new_resource.global_prefix)
    action :nothing
  end
end
