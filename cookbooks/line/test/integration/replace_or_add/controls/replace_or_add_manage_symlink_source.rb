# frozen_string_literal: true

control 'replace_or_add_manage_symlink_source' do
  describe command('test -L /tmp/replace_or_add_symlink') do
    its('exit_status') { should eq 0 }
  end

  describe file('/tmp/replace_or_add_symlink') do
    it { should exist }
    its('content') { should match(/^updated through target$/) }
  end

  describe file('/tmp/replace_or_add_symlink_target') do
    it { should exist }
    its('content') { should match(/^updated through target$/) }
  end

  describe file('/tmp/replace_or_add_manage_symlink_source_false') do
    it { should exist }
    its('content') { should match(/^updated with explicit false$/) }
  end
end
