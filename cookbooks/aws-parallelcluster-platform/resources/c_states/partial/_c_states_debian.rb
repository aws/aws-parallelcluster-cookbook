action_class do
  def grub_variable
    'GRUB_CMDLINE_LINUX'
  end

  def grub_regenerate_boot_menu_command
    '/usr/sbin/update-grub'
  end
end
