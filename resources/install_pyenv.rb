# frozen_string_literal: true

resource_name :install_pyenv
provides :install_pyenv

# Resource to create a Python virtual environment for a given user

property :python_version, String, name_property: true

default_action :run

action :run do
  pyenv_system_install new_resource.python_version

  pyenv_python new_resource.python_version

  pyenv_plugin 'virtualenv' do
    git_url 'https://github.com/pyenv/pyenv-virtualenv'
  end

  template "/etc/profile.d/pyenv.sh" do
    source 'pyenv.sh.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end
end
