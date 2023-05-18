unified_mode true
default_action :setup

def grub_cmdline_attributes
  {
    "processor.max_cstate" => { "value" => "1" },
    "intel_idle.max_cstate" => { "value" => "1" },
  }
end

action :setup do
  return if !x86_instance? || on_docker?

  append_if_not_present_grub_cmdline(grub_cmdline_attributes, grub_variable)

  execute "Regenerate grub boot menu" do
    command grub_regenerate_boot_menu_command
  end
end

def append_if_not_present_grub_cmdline(attributes, grub_variable)
  grep_grub_cmdline = 'grep "^' + grub_variable + '=" /etc/default/grub'

  ruby_block "Append #{grub_variable} if it do not exist in /etc/default/grub" do
    block do
      if shell_out(grep_grub_cmdline).stdout.include? "#{grub_variable}="
        Chef::Log.debug("Found #{grub_variable} line")
      else
        Chef::Log.warn("#{grub_variable} not found - Adding")
        shell_out('echo \'' + grub_variable + '=""\' >> /etc/default/grub')
        Chef::Log.info("Added #{grub_variable} line")
      end
    end
    action :run
  end

  attributes.each do |attribute, properties|
    ruby_block "Add #{attribute} with value #{properties['value']} to /etc/default/grub in line #{grub_variable} if it is not present" do
      block do
        command_out = shell_out(grep_grub_cmdline).stdout
        if command_out.include? "#{attribute}"
          Chef::Log.warn("Found #{attribute} in #{grub_variable} - #{grub_variable} value: #{command_out}")
        else
          Chef::Log.info("#{attribute} not found - Adding")
          shell_out('sed -i \'s/^\(' + grub_variable + '=".*\)"$/\1 ' + attribute + '=' + properties['value'] + '"/g\' /etc/default/grub')
          Chef::Log.info("Added #{attribute}=#{properties['value']} to #{grub_variable}")
        end
      end
      action :run
    end
  end
end
