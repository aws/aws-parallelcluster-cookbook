selinux_user 'test1_u' do
  level 's0'
  range 's0-s0:c0.c1023'
  roles %w(unconfined_r staff_r sysadm_r)
end

selinux_user 'test2_u' do
  roles %w(staff_r)
end
