# frozen_string_literal: true

resource_name :pyenv_command
provides :pyenv_command

property :command, String, name_property: true
property :user, String, required: true
property :pyenv_path, String, required: true
property :home_dir, String, default: lazy { ::File.expand_path("~#{user}") }

default_action :run

action :run do
  cmd_env = {
    'PYENV_ROOT' => new_resource.pyenv_path,
    'PATH' => "#{new_resource.pyenv_path}/bin:#{ENV['PATH']}",
    'USER' => new_resource.user,
    'HOME' => new_resource.home_dir
  }
  bash "pyenv #{new_resource.command}" do
    code <<-PYENV_COMMAND
    pyenv #{new_resource.command}
    PYENV_COMMAND
    user new_resource.user
    environment cmd_env
  end
end
