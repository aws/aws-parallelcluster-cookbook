unified_mode true

property :pyenv_version,
          String

property :code,
          String

property :creates,
          String

property :cwd,
          String

property :environment,
          Hash

property :group,
          String

property :path,
          Array

property :returns,
          Array,
          default: [0]

property :timeout,
          Integer

property :user,
          String

property :umask,
          [String, Integer]

property :live_stream,
          [true, false],
          default: false

action :run do
  execute new_resource.name do
    command     script_code
    creates     new_resource.creates
    cwd         new_resource.cwd
    user        new_resource.user
    group       new_resource.group
    returns     new_resource.returns
    timeout     new_resource.timeout
    umask       new_resource.umask
    live_stream new_resource.live_stream
    environment(script_environment)
  end
end

action_class do
  include PyEnv::Cookbook::ScriptHelpers
end
