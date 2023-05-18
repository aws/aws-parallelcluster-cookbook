unified_mode true

property :python_version,
          String,
          name_property: true
property :path,
          String,
          required: true

property :user,
          String

action :create do
  pyenv_script 'local' do
    code "pyenv local #{new_resource.python_version}"
    cwd new_resource.path
    user new_resource.user if new_resource.user
    action :run
    not_if { current_local_version_correct? }
  end
end

action_class do
  include PyEnv::Cookbook::ScriptHelpers

  def current_local_version_correct?
    current_local_version == new_resource.python_version
  end

  def current_local_version
    version_file = ::File.join(new_resource.path, '.python-version')

    ::File.exist?(version_file) && ::IO.read(version_file).chomp
  end
end
