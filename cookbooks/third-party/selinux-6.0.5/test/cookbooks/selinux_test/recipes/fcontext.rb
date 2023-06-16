directory '/opt/selinux-test'

%w( foo bar baz ).each do |f|
  file "/opt/selinux-test/#{f}"
end

directory '/opt/selinux-test/quux'

# single file
selinux_fcontext '/opt/selinux-test/foo' do
  secontext 'httpd_sys_content_t'
end

# regex
selinux_fcontext '/opt/selinux-test/b.+' do
  secontext 'boot_t'
end

# file type
selinux_fcontext '/opt/selinux-test/.+' do
  secontext 'etc_t'
  file_type 'd'
end
