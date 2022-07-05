#
# Delete lines using regex pattern
#

control 'delete_lines_regexp' do
  describe file('/tmp/regexp_pattern_1') do
    it { should exist }
    its('content') { should_not match /^HELLO.*/ }
  end
  describe file_ext('/tmp/regexp_pattern_1') do
    it { should have_correct_eol }
    its('size_lines') { should eq 4 }
  end

  describe file('/tmp/regexp_pattern_2') do
    it { should exist }
    its('content') { should_not match /^#.*/ }
  end
  describe file_ext('/tmp/regexp_pattern_2') do
    it { should have_correct_eol }
    its('size_lines') { should eq 4 }
  end
end
