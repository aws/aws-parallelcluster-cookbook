
venv_root = "/home/#{user}/venv_test"

control 'VirtualEnv' do
  impact 0.7
  title 'A human-readable title'
  desc 'An optional description ...'

  desc 'Pip should install package virtualenv'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && pip show virtualenv'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 16.2.0') }
  end

  desc 'Pip should upgrade package urllib3 inside virtualenv'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show urllib3'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 1.25.11') }
  end

  desc 'Pip should install package fire inside virtualenv according to requirements.txt'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show fire'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 0.1.2') }
  end

  desc 'Pip should uninstall package requests inside virtualenv'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show requests'") do
    its('exit_status') { should eq(1) }
  end
end

control 'virtualenv should be created' do
  title "virtualenv should be created in #{venv_root}"

  describe directory(venv_root) do
    it { should exist }
    its('owner') { should eq('root') }
  end

  describe file("#{venv_root}/bin/activate") do
    it { should be_file }
    its('owner') { should eq('root') }
  end
end
