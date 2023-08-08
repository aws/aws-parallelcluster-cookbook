unified_mode true

property :version,
          String,
          name_property: true

property :version_file,
          String

property :user,
          String

property :environment,
          Hash

property :verbose,
          [true, false],
          default: false

action :install do
  install_start = Time.now

  Chef::Log.info("Building Python #{new_resource.version}, this could take a while...")

  command = %(pyenv install #{verbose} #{new_resource.version})

  pyenv_script "#{command}" do
    code        command
    user        new_resource.user
    environment new_resource.environment
    live_stream new_resource.verbose
    action      :run
    not_if { python_installed? }
  end

  Chef::Log.info("#{new_resource} build time was #{(Time.now - install_start) / 60.0} minutes")
end

action :uninstall do
  command = %(pyenv uninstall -f #{new_resource.version})

  pyenv_script "#{command}" do
    code        command
    user        new_resource.user
    environment new_resource.environment
    live_stream new_resource.verbose
    action      :run
    not_if { python_installed? }
  end
end

action_class do
  include PyEnv::Cookbook::ScriptHelpers

  def python_installed?
    ::File.directory?(::File.join(root_path, 'versions', new_resource.version))
  end

  def verbose
    return '-v' if new_resource.verbose
  end
end
