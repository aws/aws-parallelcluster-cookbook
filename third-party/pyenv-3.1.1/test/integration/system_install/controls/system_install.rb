# frozen_string_literal: true

global_python = '3.7.1'
venv_root = '/opt/venv_test'

control 'pyenv should be installed' do
  title 'pyenv should be installed globally'

  desc "Can set global Python versions to #{global_python}"
  describe bash('source /etc/profile.d/pyenv.sh && pyenv global') do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match(global_python) }
    its('stdout')      { should_not match('system') }
  end

  desc "Python #{global_python} should be installed"
  describe bash('source /etc/profile.d/pyenv.sh && python --version') do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match(global_python) }
  end

  desc 'Plugin should be installed'
  describe bash('source /etc/profile.d/pyenv.sh && pyenv virtualenv') do
    its('stderr') { should match('pyenv-virtualenv') }
  end

  desc 'Pip should install package requests'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && pip show requests'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 2.18.3') }
  end

  desc 'Pip should install package virtualenv'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && pip show virtualenv'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 16.2.0') }
  end

  desc 'Pip should install package requests inside virtualenv according to requirements.txt'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show fire'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 0.1.2') }
  end

  desc 'Pip should uninstall package requests inside virtualenv'
  describe bash("sudo -H bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show requests'") do
    its('exit_status') { should eq(1) }
  end
end

control 'pyenv should be installed to the system path' do
  title 'pyenv should be installed in the global location'

  describe file('/etc/profile.d/pyenv.sh') do
    it { should be_file }
    it { should be_executable }
    its('owner') { should eq('root') }
  end

  describe directory('/usr/local/pyenv') do
    it { should exist }
    its('owner') { should eq('root') }
  end

  describe file('/usr/local/pyenv/bin/pyenv') do
    it { should be_file }
    it { should be_executable }
    its('owner') { should eq('root') }
  end

  describe file('/usr/local/pyenv/shims/pip') do
    it { should be_file }
    it { should be_executable }
    its('owner') { should eq('root') }
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
