#
# Test for lists with 3 delimitors and a terminal ([], [])
#

control 'add_to_list_3d_terminal' do
  describe file('/tmp/3d_term') do
    it { should exist }
    its('content') { should match /^multi = \(\[310\], \[323\], \[789\]\)$/ }
    its('content') { should match /^empty_3delim=\(\[3_with_end\]\)$/ }
  end
  describe file_ext('/tmp/3d_term') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
