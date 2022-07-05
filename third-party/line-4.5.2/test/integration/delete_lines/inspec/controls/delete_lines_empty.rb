#
# Delete lines on empty file
#

control 'delete_lines_empty' do
  describe file('/tmp/emptyfile') do
    it { should exist }
    its('size') { should eq 0 }
  end

  describe file('/tmp/missingfile') do
    it { should_not exist }
  end
end
