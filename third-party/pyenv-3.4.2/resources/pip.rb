#
# Cookbook:: pyenv
# Resource:: pip
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
provides :pyenv_pip

property :package_name, String, name_property: true
property :virtualenv,   String
property :version,      String
property :user,         String
property :options,      String
property :requirement,  [true, false], default: false
property :editable,     [true, false], default: false

action :install do
  install_mode = if new_resource.requirement
                   '--requirement'
                 elsif new_resource.editable
                   '--editable'
                 else
                   ''
                 end

  install_target = if new_resource.version
                     "#{new_resource.package_name}==#{new_resource.version}"
                   else
                     new_resource.package_name.to_s
                   end

  pip_args = "install #{new_resource.options} #{install_mode} #{install_target}"

  # without virtualenv, install package with system's pip
  command = if new_resource.virtualenv
              "#{new_resource.virtualenv}/bin/pip #{pip_args}"
            else
              "pip #{pip_args}"
            end

  pyenv_script new_resource.package_name do
    code command
    user new_resource.user if new_resource.user
    only_if { require_install? }
  end
end

action :upgrade do
  upgrade_target = if new_resource.version
                     "#{new_resource.package_name}==#{new_resource.version}"
                   else
                     new_resource.package_name.to_s
                   end

  pip_args = "install --upgrade #{new_resource.options} #{upgrade_target}"

  # without virtualenv, upgrade package with system's pip
  command = if new_resource.virtualenv
              "#{new_resource.virtualenv}/bin/pip #{pip_args}"
            else
              "pip #{pip_args}"
            end

  pyenv_script new_resource.package_name do
    code command
    user new_resource.user if new_resource.user
    only_if { require_upgrade? }
  end
end

action :uninstall do
  uninstall_mode = if new_resource.requirement
                     '--requirement'
                   else
                     ''
                   end

  pip_args = ["uninstall --yes #{new_resource.options}",
              "#{uninstall_mode} #{new_resource.package_name}"].join

  # without virtualenv, uninstall package with system's pip
  command = if new_resource.virtualenv
              "#{new_resource.virtualenv}/bin/pip #{pip_args}"
            else
              "pip #{pip_args}"
            end

  pyenv_script new_resource.package_name do
    code command
    user new_resource.user if new_resource.user
  end
end

action_class do
  include Chef::Pyenv::ScriptHelpers

  def require_install?
    current_version = get_current_version
    return true unless current_version

    unless new_resource.version
      Chef::Log.debug("already installed: #{new_resource.package_name} #{current_version}")
      return false
    end

    is_different_version?(current_version)
  end

  def require_upgrade?
    current_version = get_current_version
    return true unless current_version

    is_different_version?(current_version)
  end

  def get_current_version
    current_version = nil
    show = pip_command("show #{new_resource.package_name}").stdout
    show.split(/\n+/).each do |line|
      current_version = line.split(/\s+/)[1] if line.start_with?('Version:')
    end
    Chef::Log.debug("current_version: #{new_resource.package_name} #{current_version}")
    unless current_version
      Chef::Log.debug("not installed: #{new_resource.package_name}")
    end
    current_version
  end

  def is_different_version?(current_version)
    if current_version != new_resource.version
      Chef::Log.debug("different version installed: #{new_resource.package_name} current=#{current_version} candidate=#{new_resource.version}")
      true
    else
      Chef::Log.debug("same version installed: #{new_resource.package_name} #{current_version}")
      false
    end
  end
end
