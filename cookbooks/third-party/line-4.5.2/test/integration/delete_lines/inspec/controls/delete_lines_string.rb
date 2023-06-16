#
# Delete lines using string pattern
#

control 'delete_lines_string' do
  describe file('/tmp/string_pattern_1') do
    it { should exist }
    its('content') { should_not match /^HELLO.*/ }
  end
  describe file_ext('/tmp/string_pattern_1') do
    it { should have_correct_eol }
    its('size_lines') { should eq 4 }
  end

  describe file('/tmp/string_pattern_2') do
    it { should exist }
    its('content') { should_not match /^#.*/ }
  end
  describe file_ext('/tmp/string_pattern_2') do
    it { should have_correct_eol }
    its('size_lines') { should eq 4 }
  end
end
