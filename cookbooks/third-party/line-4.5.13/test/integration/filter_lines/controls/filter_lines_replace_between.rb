#
# Spec tests for the replace_between filter
#

control 'filter_lines_replace_between' do
  describe file('/tmp/replace_between') do
    it { should exist }
    its('content') { should match(/FOOL\r?\nline1\r?\nline2\r?\nline3\r?\nint/) }
  end
  describe matches('/tmp/replace_between', /FOOL\r?\nline1\r?\nline2\r?\nline3\r?\nint/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/replace_between') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end
end
