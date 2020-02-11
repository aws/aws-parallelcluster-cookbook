# frozen_string_literal: true

resource_name :virtualenv_pip
provides :virtualenv_pip

default_action :install

# Resource to install packages into a virtualenv

property :package_handle, String, name_property: true
property :virtualenv_path, String, required: true
property :user, String, default: 'root'
property :is_requirements_list, [true, false], default: false
property :version, String

action :install do
  pip_path = ::File.join(new_resource.virtualenv_path, 'bin', 'pip')
  raise "no pip found at #{pip_path}" unless ::File.exist?(pip_path)

  raise "can't specify version when using requirements list" if new_resource.is_requirements_list && new_resource.version

  requirements_flag = if new_resource.is_requirements_list
                        "--requirement"
                      else
                        ""
                      end

  execute "#{pip_path} install #{requirements_flag} #{new_resource.package_handle}" do
    user new_resource.user
  end
end
