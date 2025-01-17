#
# Change last line
#

control 'replace_or_add_change_line' do
  describe file('/tmp/change_line_eof') do
    it { should exist }
  end
  describe matches('/tmp/change_line_eof', /^Last line changed$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/change_line_eof') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end
end
