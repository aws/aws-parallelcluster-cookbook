include_controls 'common'

control 'permissive' do
  title 'Verify that SELinux permissive contexts are set correctly'

  describe command('semanage permissive -l') do
    its('stdout') { should match 'httpd_t' }
    its('stdout') { should match 'user_t' }
  end
end
