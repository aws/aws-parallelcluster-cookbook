#
# Spec tests for the replace filter
#

control 'filter_lines_replace' do
  describe file('/tmp/replace') do
    it { should exist }
    its('content') { should_not match /^HELLO THERE I AM DANGERFILE/ }
    its('content') { should_not match /^COMMENT ME AND I STOP YELLING I PROMISE/ }
  end
  describe matches('/tmp/replace', /line1\r?\nline2\r?\nline3\r?\n/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/replace') do
    it { should have_correct_eol }
    its('size_lines') { should eq 9 }
  end
end
