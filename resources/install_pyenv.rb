resource_name :install_pyenv
provides :install_pyenv

# Resource to create a Python virtual environment for a given user

property :pyenv_user, String, name_property: true
property :python_version, String, required: true

default_action :run

action :run do

  pyenv_user_install new_resource.pyenv_user

  pyenv_python new_resource.python_version do
    user new_resource.pyenv_user
  end

  pyenv_plugin 'virtualenv' do
    git_url 'https://github.com/pyenv/pyenv-virtualenv'
    user new_resource.pyenv_user
  end
end