# frozen_string_literal: true

title 'DNF Modules'

control 'yum-dnf-module-01' do
  impact 1.0
  title 'Requested DNF modules are configured'

  describe command('dnf module list') do
    its('stdout') { should match /nodejs +12 \[e\]/ }
    its('stdout') { should match /ruby +2.7 \[e\]/ }
    its('stdout') { should match /php +remi-8.1 \[e\]/ }
    its('stdout') { should match /mysql.+\[x\]/ }
  end
end

control 'yum-dnf-module-02' do
  impact 1.0
  title 'Packages from configured modules are installed'

  describe command('node --version') do
    its('stdout') { should match /v12/ }
  end

  describe command('ruby --version') do
    its('stdout') { should match /ruby 2.7/ }
  end

  describe command('php --version') do
    its('stdout') { should match /PHP 8.1/ }
  end
end
