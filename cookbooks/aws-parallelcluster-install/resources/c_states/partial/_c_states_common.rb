unified_mode true
default_action :setup

def grub_cmdline_attributes
  {
    "processor.max_cstate" => { "value" => "1" },
    "intel_idle.max_cstate" => { "value" => "1" },
  }
end

action :setup do
  return if !x86? || virtualized?

  append_if_not_present_grub_cmdline(grub_cmdline_attributes, grub_variable)

  execute "Regenerate grub boot menu" do
    command grub_regenerate_boot_menu_command
  end
end
