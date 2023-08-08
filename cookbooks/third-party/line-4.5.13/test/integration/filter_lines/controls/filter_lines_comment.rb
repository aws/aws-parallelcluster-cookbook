#
# Spec tests for the comment filter
#

control 'filter_lines_comment' do
  describe file('/tmp/comment') do
    it { should exist }
    its('content') { should_not match /^COMMENT ME/ }
  end
  describe matches('/tmp/comment', /^#/) do
    its('count') { should eq 3 }
  end
  describe file_ext('/tmp/comment') do
    it { should have_correct_eol }
    its('size_lines') { should eq 5 }
  end
end
