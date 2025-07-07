#
# Spec tests for the after filter
#

control 'filter_lines_after - Verify the code to use the after filter.' do
  describe file('/tmp/after_text') do
    its('content') { should match(/HELLO THERE I AM DANGERFILE\r?\nline1\r?\nline2\r?\nline3\r?\n# UN/) }
    its('content') { should match(/COMMENT ME AND I STOP YELLING I PROMISE\r?\nline1\r?\nline2\r?\nline3\r?\nint/) }
  end
  describe matches('/tmp/after_text', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/after_text') do
    it { should have_correct_eol }
    its('size_lines') { should eq 11 }
  end

  describe file('/tmp/after') do
    its('content') { should match(/HELLO THERE I AM DANGERFILE\r?\nline1\r?\nline2\r?\nline3\r?\n# UN/) }
    its('content') { should match(/COMMENT ME AND I STOP YELLING I PROMISE\r?\nline1\r?\nline2\r?\nline3\r?\nint/) }
  end
  describe matches('/tmp/after', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/after') do
    it { should have_correct_eol }
    its('size_lines') { should eq 11 }
  end

  describe file('/tmp/after_first') do
    its('content') { should match(/DANGERFILE\r?\nline1\r?\nline2\r?\nline3\r?\n# UN/) }
  end
  describe matches('/tmp/after_first', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/after_first') do
    it { should have_correct_eol }
    its('size_lines') { should eq 8 }
  end

  describe file('/tmp/after_last') do
    its('content') { should match(/I PROMISE\r?\nline1\r?\nline2\r?\nline3\r?\nint/) }
  end
  describe matches('/tmp/after_last', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/after_last') do
    it { should have_correct_eol }
    its('size_lines') { should eq 8 }
  end
end
