# frozen_string_literal: true

resource_name :install_pyenv
provides :install_pyenv
unified_mode true

# Resource:: to create a Python virtual environment for a given user

property :python_version, String, name_property: true
property :prefix, String
property :user_only, [true, false],
         default: false
property :user, String

default_action :run

action :run do
  if new_resource.user_only
    raise "user property is required for resource install_pyenv when user_only is set to true" unless new_resource.user

    pyenv_user_install new_resource.python_version do
      user new_resource.user
      user_prefix new_resource.prefix if new_resource.prefix
    end
  else
    raise "prefix property is required for resource install_pyenv when user_only is set to false" unless new_resource.prefix

    pyenv_system_install new_resource.python_version do
      global_prefix new_resource.prefix
    end

    # Remove the profile.d script that the pyenv cookbook writes.
    # This is done in order to avoid exposing the ParallelCluster pyenv installation to customers
    # on login.
    file '/etc/profile.d/pyenv.sh' do
      action :delete
    end
  end

  pyenv_python new_resource.python_version do
    user new_resource.user if new_resource.user_only
  end

  pyenv_plugin 'virtualenv' do
    git_url 'https://github.com/pyenv/pyenv-virtualenv'
    user new_resource.user if new_resource.user_only
  end
end
