#
# Delete from list with 1 deliminator ,
#

control 'delete_from_list_1d' do
  describe file('/tmp/1d') do
    it { should exist }
    its('content') { should match /^People to call: Bobby, Karen$/ }
    its('content') { should_not match /^\s*kernel .*\s+rhgb\s+/ }
  end
  describe file_ext('/tmp/1d') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
