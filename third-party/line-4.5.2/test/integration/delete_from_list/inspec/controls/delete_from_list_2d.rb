#
# Delete from list with 2 deliminators ||, ||
#

control 'delete_from_list_2d' do
  describe file('/tmp/2d') do
    it { should exist }
    its('content') { should match %r{^my @net1918 = \("172.16.0.0/12", "192.168.0.0/16"\);$} }
    its('content') { should match /^last_delimited_list= \(\)$/ }
  end
  describe file_ext('/tmp/2d') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
