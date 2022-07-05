#
# Add a line matching pattern
#

control 'replace_or_add_add_a_line_matching_pattern' do
  describe file('/tmp/add_a_line_matching_pattern') do
    it { should exist }
  end
  describe matches('/tmp/add_a_line_matching_pattern', /^Add another line$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/add_a_line_matching_pattern') do
    it { should have_correct_eol }
    its('size_lines') { should eq 8 }
  end
end
