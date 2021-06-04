# frozen_string_literal: true

resource_name :activate_virtual_env
provides :activate_virtual_env

# Resource to create a Python virtual environment and install a list of packages on it

property :pyenv_name, String, name_property: true
property :pyenv_path, String, required: true
property :python_version, String, required: true
property :requirements_path, String, default: ""

default_action :run

action :run do
  pyenv_script "pyenv virtualenv #{new_resource.pyenv_name}" do
    code "pyenv virtualenv #{new_resource.python_version} #{new_resource.pyenv_name}"
  end

  pyenv_pip "pip" do
    virtualenv new_resource.pyenv_path
    action :upgrade
  end

  unless new_resource.requirements_path.empty?
    # Copy requirements file
    cookbook_file "#{new_resource.pyenv_path}/requirements.txt" do
      source new_resource.requirements_path
      mode '0755'
    end

    # Install given requirements in the virtual environment
    pyenv_pip "#{new_resource.pyenv_path}/requirements.txt" do
      virtualenv new_resource.pyenv_path
      requirement true
    end
  end
end
