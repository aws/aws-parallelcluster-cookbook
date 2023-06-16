#
# Spec tests for the stanza filter
#

control 'filter_lines_stanza' do
  describe file('/tmp/stanza') do
    it { should exist }
  end
  describe ini('/tmp/stanza') do
    its('libvas.use-dns-srv') { should cmp 'false' }
    its('libvas.mscldap-timeout') { should cmp 5 }
    its('nss_vas.addme') { should cmp 'option' }
    its('nss_vas.lowercase-names') { should cmp 'false' }
    its('test1.line1') { should cmp 'true' }
    its('test2/test.line1') { should cmp 'false' }
  end
  describe file_ext('/tmp/stanza') do
    it { should have_correct_eol }
    its('size_lines') { should eq 30 }
  end
end
