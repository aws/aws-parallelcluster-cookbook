unified_mode true

property :user,
          String

action :run do
  pyenv_script 'pyenv rehash' do
    code %(pyenv rehash)
    user new_resource.user
    action :run
  end
end

action_class do
  include PyEnv::Cookbook::ScriptHelpers
end
