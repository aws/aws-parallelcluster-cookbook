
#
# Append to simple file
#

control 'append_if_no_line_single_line' do
  describe file('/tmp/single_line_file') do
    it { should exist }
    its('content') { should match /^single line file$/ }
    its('content') { should match /^SHOULD GO ON ITS OWN LINE$/ }
  end
  describe file_ext('/tmp/single_line_file') do
    it { should have_correct_eol }
    its('size_lines') { should eq 2 }
  end
end
