# frozen_string_literal: true

resource_name :install_pyenv
provides :install_pyenv

# Resource to create a Python virtual environment for a given user

property :user, String, name_property: true
property :python_version, String, required: true

default_action :run

action :run do
  home_dir = ::File.expand_path("~#{new_resource.user}")
  user_prefix = ::File.join(home_dir, '.pyenv')

  unless ::File.directory?(::File.join(user_prefix, 'versions', new_resource.python_version))
    # Install required packages
    package node['cfncluster']['pyenv_packages']

    # Install pyenv
    git user_prefix do
      repository 'https://github.com/pyenv/pyenv.git'
      reference  'master'
      user       new_resource.user
      group      new_resource.user
      action     :checkout
    end

    # Install pyenv's virtualenv plugin
    git ::File.join(user_prefix, 'plugins', 'virtualenv') do
      repository  'https://github.com/pyenv/pyenv-virtualenv'
      reference   'master'
      user        new_resource.user
      group       new_resource.user
      action      :checkout
    end

    # Install desired version of python
    pyenv_command "install #{new_resource.python_version}" do
      user new_resource.user
      pyenv_path user_prefix
    end
  end
end
