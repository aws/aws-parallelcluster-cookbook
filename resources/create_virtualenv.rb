# frozen_string_literal: true

resource_name :create_virtualenv
provides :create_virtualenv

# Resource to create a Python virtual environment for a given user and install a list of packages on it

property :virtualenv_name, String, name_property: true
property :virtualenv_path, String, required: true
property :user, String, default: 'root'
property :python_version, String, required: true
property :requirements_path, String, default: ""
property :pyenv_root, String

default_action :run

action :run do
  pyenv_root = new_resource.pyenv_root
  pyenv_root ||= ::File.join(::File.expand_path("~#{new_resource.user}"), '.pyenv')

  pyenv_command "virtualenv #{new_resource.python_version} #{new_resource.virtualenv_name}" do
    user new_resource.user
    pyenv_path pyenv_root
  end

  unless new_resource.requirements_path.empty?
    # Copy requirements file
    cookbook_file "#{new_resource.virtualenv_path}/requirements.txt" do
      source new_resource.requirements_path
      owner new_resource.user
      group new_resource.user
      mode '0755'
    end

    # Install given requirements in the virtual environment
    virtualenv_pip "#{new_resource.virtualenv_path}/requirements.txt" do
      virtualenv_path new_resource.virtualenv_path
      user new_resource.user
      is_requirements_list true
    end
  end
end
