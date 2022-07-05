resource_name :dnf_module
provides :dnf_module

unified_mode true

property :module_name, String,
          name_property: true,
          description: 'Name of the module to install'

property :options, [String, Array],
          coerce: proc { |x| Array(x) },
          default: [],
          description: 'Any additional options to pass to DNF'

property :flush_cache, [true, false],
          default: true,
          description: 'Whether to flush the Chef package cache after enabling the module'

action_class do
  def supported?
    (platform_family?('rhel') && node['platform_version'].to_i >= 8) || platform?('fedora')
  end

  def list_modules(type)
    raw_output = shell_out!('dnf -q module list').stdout.split("\n")
    raw_output.keep_if { |l| l.match? /\[#{type}\]/ }
    raw_output.map { |l| "#{l.split[0]}:#{l.split[1]}" }[0..-2] # remove Hint: line from end
  end

  def enabled_modules
    # extract modules from the rest of the output -- the lines with [e] (for enabled)
    list_modules('e')
  end

  def disabled_modules
    # extract modules from the rest of the output -- the lines with [x] (for disabled)
    # disable disables all versions of the stream, so add entry without :version
    dl = list_modules('x')
    dl + dl.map { |m| m.split(':').first }.uniq
  end

  def installed_modules
    # extract modules from the rest of the output -- the lines with [i] (for installed)
    list_modules('i')
  end

  def opts
    new_resource.options.join(' ')
  end

  def flush_dnf_cache
    # After switching to a new module installed during the Chef run, Chef's
    # internal package cache won't pick up on new module packages automatically,
    # so we need to reload that manually, much like after adding a new repo.
    # This isn't needed for modules available at the start of the Chef run.
    if new_resource.flush_cache
      package "flush package cache #{new_resource.module_name}" do
        action :flush_cache
      end
    end
  end
end

action :switch_to do
  return unless supported?

  unless enabled_modules.include?(new_resource.module_name)
    converge_by "switch to #{new_resource.module_name}" do
      shell_out!("dnf -qy module switch-to #{opts} '#{new_resource.module_name}'")
    end
    flush_dnf_cache
  end
end

action :enable do
  return unless supported?

  unless enabled_modules.include?(new_resource.module_name)
    converge_by "enable #{new_resource.module_name}" do
      shell_out!("dnf -qy module enable #{opts} '#{new_resource.module_name}'")
    end
    flush_dnf_cache
  end
end

action :disable do
  return unless supported?

  unless disabled_modules.include?(new_resource.module_name)
    converge_by "disable #{new_resource.module_name}" do
      shell_out!("dnf -qy module disable #{opts} '#{new_resource.module_name}'")
    end
    flush_dnf_cache
  end
end

action :install do
  return unless supported?

  unless installed_modules.include?(new_resource.module_name)
    converge_by "install #{new_resource.module_name}" do
      shell_out!("dnf -qy module install #{opts} '#{new_resource.module_name}'")
    end
    flush_dnf_cache
  end
end

action :remove do
  return unless supported?

  if installed_modules.include?(new_resource.module_name)
    converge_by "remove #{new_resource.module_name}" do
      shell_out!("dnf -qy module remove #{opts} '#{new_resource.module_name}'")
    end
    flush_dnf_cache
  end
end

action :reset do
  return unless supported?

  converge_by "reset #{new_resource.module_name}" do
    shell_out!("dnf -qy module reset #{opts} '#{new_resource.module_name}'")
  end
  flush_dnf_cache
end
