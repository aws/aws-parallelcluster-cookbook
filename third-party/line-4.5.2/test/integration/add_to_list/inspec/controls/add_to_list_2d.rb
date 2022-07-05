#
# Test for lists with 2 delimitors ||, ||
#

control 'add_to_list_2d' do
  describe file('/tmp/2d') do
    it { should exist }
    its('content') { should match /^wo2d_empty="single"$/ }
    its('content') { should match /^wo2d_list="first2","second2","third2"$/ }
  end
  describe file_ext('/tmp/2d') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
