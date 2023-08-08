#
# Delete from empty file
#

control 'delete_from_list_empty' do
  describe file('/tmp/emptyfile') do
    it { should exist }
    its('size') { should eq 0 }
  end

  describe file('/tmp/missingfile') do
    it { should_not exist }
  end
end
