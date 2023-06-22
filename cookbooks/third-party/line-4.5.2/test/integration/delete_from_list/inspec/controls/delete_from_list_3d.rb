#
# Delete from list with 3 deliminators [], []
#

control 'delete_from_list_3d' do
  describe file('/tmp/3d') do
    it { should exist }
    its('content') { should match /^multi = \(\[310\]\)$/ }
    its('content') { should match /^wo3d_list=\[second3\]$/ }
  end
  describe file_ext('/tmp/3d') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
