# frozen_string_literal: true

global_python = '3.6.1'
user          = 'vagrant'
venv_root     = "/home/#{user}/venv_test"

control 'pyenv should be installed' do
  title 'pyenv should be installed to the users home directory'

  desc "Can set global Python versions to #{global_python}"
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && pyenv global'") do
    its('exit_status') { should eq(0) }
    its('stdout') { should match(global_python) }
    its('stdout') { should_not match('system') }
  end

  desc "Python #{global_python} should be installed"
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && python --version'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match(global_python) }
  end

  desc 'Plugin should be installed'
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && pyenv virtualenv'") do
    its('stderr') { should match('pyenv-virtualenv') }
  end

  desc 'Pip should install package requests'
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && pip show requests'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 2.18.3') }
  end

  desc 'Pip should install package virtualenv'
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && pip show virtualenv'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 16.2.0') }
  end

  desc 'Pip should install package fire inside virtualenv according to requirements.txt'
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show fire'") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('Version: 0.1.2') }
  end

  desc 'Pip should uninstall package requests inside virtualenv'
  describe bash("sudo -H -u #{user} bash -c 'source /etc/profile.d/pyenv.sh && #{venv_root}/bin/pip show requests'") do
    its('exit_status') { should eq(1) }
  end
end

control 'pyenv should be installed to the user path' do
  title "pyenv should be installed in the user's home"

  describe file('/etc/profile.d/pyenv.sh') do
    it { should be_file }
    it { should be_executable }
    its('owner') { should eq('root') }
    its('content') { should match(/^\s+pyenv_init="pyenv init -"/) }
    its('content') { should match(/Rehashing will fail in a system install\n\s+pyenv_init="pyenv init - --no-rehash"/m) }
    its('content') { should match(/^\s+eval "\$\(\$pyenv_init\)"/) }
  end

  describe directory("/home/#{user}/.pyenv") do
    it { should exist }
    its('owner') { should eq(user) }
  end

  describe file("/home/#{user}/.pyenv/bin/pyenv") do
    it { should be_file }
    it { should be_executable }
    its('owner') { should eq(user) }
  end

  describe file("/home/#{user}/.pyenv/shims/pip") do
    it { should be_file }
    it { should be_executable }
    its('owner') { should eq(user) }
  end
end

control 'virtualenv should be created' do
  title "virtualenv should be created in #{venv_root}"

  describe directory(venv_root) do
    it { should exist }
    its('owner') { should eq(user) }
  end

  describe file("#{venv_root}/bin/activate") do
    it { should be_file }
    its('owner') { should eq(user) }
  end
end
