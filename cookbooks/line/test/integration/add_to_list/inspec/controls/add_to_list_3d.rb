#
# Test for lists with 3 delimitors [], []
#

control 'add_to_list_3d' do
  describe file('/tmp/3d') do
    it { should exist }
    its('content') { should match /^wo3d_empty=\[single\]$/ }
    its('content') { should match /^wo3d_list=\[first3\],\[second3\],\[third3\]$/ }
  end
  describe file_ext('/tmp/3d') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
