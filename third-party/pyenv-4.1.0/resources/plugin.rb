unified_mode true

property :git_url,
          String,
          required: true

property :git_ref,
          String,
          default: 'master'

property :environment,
          Hash

property :user,
         String

# https://github.com/pyenv/pyenv/wiki/Plugins
action :install do
  # If we pass in a username, we then install the plugin to the user's home_dir
  # See chef_pyenv_script_helpers.rb for root_path
  git "Install #{new_resource.name} plugin" do
    checkout_branch 'deploy'
    destination ::File.join(root_path, 'plugins', new_resource.name)
    repository  new_resource.git_url
    reference   new_resource.git_ref
    user        new_resource.user
    action      :sync
    environment(new_resource.environment)
  end
end

action_class do
  include PyEnv::Cookbook::ScriptHelpers
end
