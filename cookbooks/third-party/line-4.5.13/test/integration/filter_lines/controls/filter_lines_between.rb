#
# Spec tests for the between filter
#

control 'filter_lines_between' do
  describe file('/tmp/between') do
    it { should exist }
    its('content') { should match /^empty_list=\r?\nadd line\r?\nempty_delimited_list=\(\)$/ }
  end
  describe matches('/tmp/between', /^add line$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/between') do
    it { should have_correct_eol }
    its('size_lines') { should eq 21 }
  end
end
