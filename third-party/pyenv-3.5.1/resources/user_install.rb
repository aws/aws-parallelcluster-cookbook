#
# Cookbook:: pyenv
# Resource:: user_install
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

provides :pyenv_user_install

property :user,         String, name_property: true
property :git_url,      String, default: node['pyenv']['git_url']
property :git_ref,      String, default: node['pyenv']['git_ref']
property :group,        String, default: lazy { user }
property :home_dir,     String, default: lazy { ::File.expand_path("~#{user}") }
property :user_prefix,  String, default: lazy { ::File.join(home_dir, '.pyenv') }
property :environment,  Hash
property :update_pyenv, [true, false], default: true

action :install do
  node.run_state['sous-chefs'] ||= {}
  node.run_state['sous-chefs']['pyenv'] ||= {}
  node.run_state['sous-chefs']['pyenv']['root_path'] ||= {}

  node.run_state['sous-chefs']['pyenv']['root_path'][new_resource.user] ||= new_resource.user_prefix

  apt_update 'update'
  build_essential 'build packages'
  package node['pyenv']['prerequisites']

  system_prefix = node.run_state['sous-chefs']['pyenv']['root_path']['system']

  template '/etc/profile.d/pyenv.sh' do
    cookbook 'pyenv'
    source   'pyenv.sh'
    owner    'root'
    mode     '0755'
    variables(global_prefix: system_prefix) if system_prefix
  end

  git new_resource.user_prefix do
    checkout_branch 'deploy'
    repository new_resource.git_url
    reference  new_resource.git_ref
    user       new_resource.user
    group      new_resource.group
    action     :checkout if new_resource.update_pyenv == false
    environment(new_resource.environment)

    notifies :run, 'ruby_block[Add pyenv to PATH]', :immediately
  end

  %w(plugins shims versions).each do |d|
    directory "#{new_resource.user_prefix}/#{d}" do
      owner new_resource.user
      group new_resource.group
      mode '0755'
    end
  end

  # Initialize pyenv
  ruby_block 'Add pyenv to PATH' do
    block do
      ENV['PATH'] = "#{new_resource.user_prefix}/shims:#{new_resource.user_prefix}/bin:#{ENV['PATH']}"
    end
    action :nothing
  end

  bash "Initialize user #{new_resource.user} pyenv" do
    code %(PATH="#{new_resource.user_prefix}/bin:$PATH" pyenv init -)
    environment('PYENV_ROOT' => new_resource.user_prefix)
    action :nothing
    subscribes :run, "git[#{new_resource.user_prefix}]", :immediately
    # Subscribe because it's easier to find the resource ;)
  end
end
