resource_name :activate_virtual_env
provides :activate_virtual_env

property :pyenv_name, String, name_property: true
property :pyenv_path, String, required: true
property :pyenv_user, String, default: 'root'
property :python_version, String, required: true
property :requirements_path, String, default: ""

default_action :run

action :run do
  pyenv_script "pyenv virtualenv #{new_resource.pyenv_name}" do
    code "pyenv virtualenv #{new_resource.python_version} #{new_resource.pyenv_name}"
    user new_resource.pyenv_user
  end

  unless new_resource.requirements_path.empty?
    # Install requirements file
    cookbook_file "#{new_resource.pyenv_path}/requirements.txt" do
      source new_resource.requirements_path
      owner new_resource.pyenv_user
      group new_resource.pyenv_user
      mode '0755'
    end

    pyenv_pip "#{new_resource.pyenv_path}/requirements.txt" do
      virtualenv new_resource.pyenv_path
      requirement true
      user new_resource.pyenv_user
    end
  end
end