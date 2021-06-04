#
# Cookbook:: selinux_module_test
#        Recipe:: remove
#

selinux_install 'selinux os prep'
selinux_module 'test' do
  action :remove
end

# EOF
