selinux_install 'install packages'

selinux_state 'permissive' do
  action :permissive
end

selinux_state 'enforcing' do
  action :enforcing
end

selinux_state 'disabled' do
  action :disabled
end
