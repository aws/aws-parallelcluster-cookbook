# frozen_string_literal: true

resource_name :install_pyenv
provides :install_pyenv
unified_mode true

# Resource:: to create a Python virtual environment for a given user

property :python_version, String, name_property: true
property :prefix, String, required: true

default_action :run

action :run do
  pyenv_system_install new_resource.python_version do
    global_prefix new_resource.prefix
  end

  # Remove the profile.d script that the pyenv cookbook writes.
  # This is done in order to avoid exposing the ParallelCluster pyenv installation to customers
  # on login.
  file '/etc/profile.d/pyenv.sh' do
    action :delete
  end

  pyenv_python new_resource.python_version

  pyenv_plugin 'virtualenv' do
    git_url 'https://github.com/pyenv/pyenv-virtualenv'
  end
end
