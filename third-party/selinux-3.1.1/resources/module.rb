#
# Cookbook:: selinux
# Resource:: module
#
# Copyright:: 2016-2019, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

property :source, String
property :base_dir, String, default: '/etc/selinux/local'
property :force, [true, false], default: false

action :create do
  # base directory to save all the selinux files from this cookbook
  base_dir = directory new_resource.base_dir do
    action :create
  end

  # finding source file path based on provider runtime attributes
  sefile_source_path = find_source_file_path
  # informed file extension (source attribute)
  sefile_source_ext = ::File.extname(sefile_source_path)

  unless sefile_source_ext == '.te'
    log "SELinux must be a `.te` extention, informed: '#{sefile_source_ext}'" do
      level :fatal
    end
  end

  # helper class to read meta-information about the SELinux Module
  sefile_source = SELinux::File.new(::File.open(sefile_source_path).read)
  # based on full path, extracting the file-name
  sefile_name = ::File.basename(sefile_source_path)

  # using based directory plus file-name to create destination path and also
  # for (to be compiled) `.pp` module
  sefile_target_path = ::File.join(base_dir.path, sefile_name)
  sefile_pp_target_path = ::File.join(
    base_dir.path,
    # inline extension swap, from `.te` to `.pp`
    ::File.basename(sefile_source_path, '.te') + '.pp'
  )

  # collecting checksum's, for installed file and informe the informed on
  # provider call
  current_checksum = begin
                       checksum(sefile_target_path)
                     rescue
                       nil
                     end
  target_checksum = checksum(sefile_source_path)

  log "Current checksum: '#{current_checksum.to_s.slice(0..8)}' " \
    "('#{sefile_target_path}')"
  log "Target checksum: '#{target_checksum.to_s.slice(0..8)}' " \
    "('#{sefile_source_path}')"

  # checking if module is already installed
  semodule = SELinux::Module.new(sefile_source.module_name)

  # if module is installed and target files have the same checksum, this provider is up-to-date
  if semodule.installed?(sefile_source.version) && target_checksum == current_checksum
    log "SELinux module '#{sefile_source.module_name}', " \
      "version '#{sefile_source.version}', is up-to-date!"
  else
    # rendering selinux file to base directory
    sefile_target = file sefile_target_path do
      content sefile_source.content
      mode '0600'
      owner 'root'
      group 'root'
      action :create
    end

    if semodule.installed?(sefile_source.version) && !new_resource.force
      raise 'SELinux module has changed but version is already installed ' \
        "'#{sefile_name}' (v#{sefile_source.version}).\n" \
        " *** Consider a module version bump or use 'force' option. *** "
    end

    install_policy_devel_packages
    compile_selinux_modules(sefile_pp_target_path)

    execute "Installing SELinux '.pp' module: '#{sefile_pp_target_path}'" do
      command "semodule --install '#{sefile_pp_target_path}'"
      action :run
    end
  end
end

action :remove do
  semodule = SELinux::Module.new(new_resource.name)

  if semodule.installed?
    execute "Removing SELinux module: '#{new_resource.name}'" do
      command "semodule --remove='#{new_resource.name}'"
      action :run
    end
  end
end

action_class do
  include Chef::Mixin::Checksum

  # Returns the actual path of the informed 'file' attribute
  def find_source_file_path
    # determining from which cookbook to get the files from
    cookbook = run_context.cookbook_collection[@new_resource.cookbook_name]

    # using chef internals to look for the desired file and return it, when it
    # finds more than one possible occurnence error will spawn
    cookbook.preferred_filename_on_disk_location(
      run_context.node,
      :files,
      source_location
    )
  end

  # Wrapper new_resource.source to find files under 'selinux' directory, if it's
  # not started with this directory first, this method will return 'selinux' as a
  # prefix.
  def source_location
    if new_resource.source !~ %r{^selinux/}
      'selinux/' + new_resource.source
    else
      new_resource.source
    end
  end

  # Calls package installer to deploy SELinux policy development tools, which
  # will allow us to compile a module locally.
  def install_policy_devel_packages
    package %w(make policycoreutils selinux-policy-devel)
  end

  # Calling make to compile all modules on the SELinux folder, and add a hook to
  # handle desired `.pp` file creation, it will raise if not found.
  def compile_selinux_modules(sefile_pp_target_path)
    selinux_makefile = '/usr/share/selinux/devel/Makefile'

    execute "Compiling SELinux modules at '#{new_resource.base_dir}'" do
      cwd new_resource.base_dir
      command "make -C '#{new_resource.base_dir}' -f #{selinux_makefile}"
      timeout 120
      user 'root'
      notifies :run, 'ruby_block[look_for_pp_file]', :immediately
    end

    ruby_block 'look_for_pp_file' do
      block do
        Chef::Log.fatal(
          "Can't find compiled file: '#{sefile_pp_target_path}'.")
        raise "Compilation must have failed, no 'pp' " \
          "file found at: '#{sefile_pp_target_path}'"
      end
      not_if { ::File.exist?(sefile_pp_target_path) }
      action :nothing
    end
  end
end
