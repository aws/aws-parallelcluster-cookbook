#
# Test for lists with 2 delimitors and a terminal (||, ||)
#

control 'add_to_list_2d_terminal' do
  describe file('/tmp/2d_term') do
    it { should exist }
    its('content') { should match /^empty_delimited_list=\(\|empty\|\)$/ }
    its('content') { should match /^last_delimited_list= \(\|single\|, \|double\|\)$/ }
  end
  describe file_ext('/tmp/2d_term') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
