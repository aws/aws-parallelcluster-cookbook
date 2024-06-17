# frozen_string_literal: true

resource_name :activate_virtual_env
provides :activate_virtual_env
unified_mode true

# Resource:: to create a Python virtual environment and install a list of packages on it

property :pyenv_name, String, name_property: true
property :pyenv_path, String, required: true
property :python_version, String, required: true
property :requirements_path, String, default: ""
property :user, String

default_action :run

action :run do
  bash 'create venv' do
    user 'root'
    group 'root'
    cwd "#{node['cluster']['system_pyenv_root']}"
    code <<-VENV
    set -e
    versions/#{new_resource.python_version}/bin/python#{node['cluster']['python-major-minor-version']} -m venv #{new_resource.pyenv_path}
    source #{new_resource.pyenv_path}/bin/activate
    VENV
  end
end
