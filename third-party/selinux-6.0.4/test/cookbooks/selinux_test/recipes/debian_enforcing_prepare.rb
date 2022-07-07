return unless platform_family?('debian')

selinux_state 'temporary_permissive' do
  persistent false
  action :permissive
end

# Debian platforms won't allow a SELinux module to be loaded by default as it will be blocked by SELinux
selinux_module 'selinux_module_allow_loading' do
  cookbook 'selinux_test'
  source 'moduleLoad.te'
  module_name 'moduleLoad'

  action :create
end

# Ubuntu won't allow kitchen to connect by default
selinux_module 'selinux_module_allow_kitchen_converge' do
  cookbook 'selinux_test'
  source 'kitchenConverge.te'
  module_name 'kitchenConverge'

  action :create
end

# Debian platforms won't allow SELinux modules and booleans to be read by inspec over SSH
selinux_module 'selinux_module_allow_kitchen_verify' do
  cookbook 'selinux_test'
  source 'kitchenVerify.te'
  module_name 'kitchenVerify'

  action :create
end

selinux_state 'reset_enforcing' do
  action :enforcing
end
