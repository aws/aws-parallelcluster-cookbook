#
# Cookbook:: selinux_module_test
#        Recipe:: create
#

selinux_install 'selinux os prep'
selinux_module 'create' do
  source 'test.te'
  force true
  action :create
end

# EOF
