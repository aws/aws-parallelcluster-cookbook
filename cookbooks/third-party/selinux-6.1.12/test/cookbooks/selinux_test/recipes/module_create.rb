selinux_module 'test_create' do
  cookbook 'selinux_test'
  source 'test.te'
  module_name 'test'

  action :create
end
