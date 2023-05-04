#
# Test for lists with 1 delimitor and a terminal " , "
#

control 'add_to_list_1d_terminal' do
  describe file('/tmp/1d_term') do
    it { should exist }
    its('content') { should match /^DEFAULT_APPEND_EMPTY="first"$/ }
    its('content') { should match /^DEFAULT_APPEND="resume.*showopts newopt"$/ }
  end
  describe file_ext('/tmp/1d_term') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
