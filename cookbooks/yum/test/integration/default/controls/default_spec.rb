# frozen_string_literal: true

title 'Yum Global Configuration'

control 'yum-globalconfig-01' do
  impact 1.0
  title 'The global yum configuration is rendered'

  describe file('/etc/yum.conf') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('content') { should match /^\[main\]$/ }
    its('content') { should match %r{^cachedir=/var/cache/yum/\$basearch/\$releasever$} }
    its('content') { should match /^gpgcheck=1$/ }
    its('content') { should match /^plugins=1$/ }
  end
end
