include_controls 'common'

control 'user' do
  title 'Verify that SELinux user are set correctly'

  describe command('semanage user -l') do
    its('stdout') { should match /^test1_u\s+user\s+s0\s+s0-s0:c0\.c1023\s+staff_r sysadm_r unconfined_r/ }
    its('stdout') { should match /^test2_u\s+user\s+s0\s+s0\s+staff_r\s*$/ }
  end
end

control 'login' do
  title 'Verify that SELinux login mappings are set correctly'

  describe command('semanage login -l') do
    its('stdout') { should match /^test1\s+test1_u\s+s0\s*\*?\s*$/ }
    its('stdout') { should match /^test2\s+test2_u\s+s0\s*\*?\s*$/ }
  end
end
