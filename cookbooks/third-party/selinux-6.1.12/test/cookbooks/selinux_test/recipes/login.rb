user 'test1'
user 'test2'

selinux_login 'test1' do
  user 'test1_u'
  range 's0'
end

selinux_login 'test2' do
  user 'test2_u'
end
