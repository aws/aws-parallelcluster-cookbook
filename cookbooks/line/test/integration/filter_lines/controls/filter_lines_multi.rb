#
# Spec tests for the multiple filters
#

control 'filter_lines_multi' do
  describe file('/tmp/multiple_filters') do
    it { should exist }
    its('content') { should match(/^HELLO THERE I AM DANGERFILE\r?\nline1\r?\nline2\r?\nline3$/) }
    its('content') { should match(/^COMMENT ME AND I STOP YELLING I PROMISE\r?\nline1\r?\nline2\r?\nline3$/) }
    its('content') { should_not match(/^#/) }
  end
  describe file_ext('/tmp/multiple_filters') do
    it { should have_correct_eol }
    its('size_lines') { should eq 10 }
  end
end
