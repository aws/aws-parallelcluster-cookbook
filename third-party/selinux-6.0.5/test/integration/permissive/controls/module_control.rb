control 'module' do
  title 'Verify that SELinux modules are installed correctly'

  describe selinux.modules.where(name: 'test') do
    it { should exist }
    it { should be_installed }
    it { should be_enabled }
  end
end
