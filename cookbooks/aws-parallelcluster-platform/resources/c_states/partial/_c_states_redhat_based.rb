action_class do
  def grub_variable
    'GRUB_CMDLINE_LINUX_DEFAULT'
  end

  def grub_regenerate_boot_menu_command
    '/usr/sbin/grub2-mkconfig -o /boot/grub2/grub.cfg'
  end
end
