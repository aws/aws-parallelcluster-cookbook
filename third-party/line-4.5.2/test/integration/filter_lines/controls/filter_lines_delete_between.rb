#
# Spec tests for the delete_between filter
#

control 'filter_lines_delete_between' do
  describe file('/tmp/delete_between') do
    it { should exist }
    its('content') { should_not match /^kernel/ }
  end
  describe matches('/tmp/delete_between', /crashkernel/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/delete_between') do
    it { should have_correct_eol }
    its('size_lines') { should eq 18 }
  end
end
