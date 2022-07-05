#
# Spec tests for the before filter
#
control 'filter_lines_before' do
  describe file('/tmp/before') do
    its('content') { should match(/^line1\r?\nline2\r?\nline3\r?\nHELLO THERE/) }
    its('content') { should match(/^line1\r?\nline2\r?\nline3\r?\nCOMMENT ME/) }
  end
  describe matches('/tmp/before', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/before') do
    it { should have_correct_eol }
    its('size_lines') { should eq 11 }
  end

  describe file('/tmp/before_first') do
    its('content') { should match(/^line1\r?\nline2\r?\nline3\r?\nHELLO THERE/) }
    its('content') { should match(/FOOL\r?\nCOMMENT ME/) }
  end
  describe matches('/tmp/before_first', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/before_first') do
    it { should have_correct_eol }
    its('size_lines') { should eq 8 }
  end

  describe file('/tmp/before_last') do
    its('content') { should match(/^HELLO THERE/) }
    its('content') { should match(/^line1\r?\nline2\r?\nline3\r?\nCOMMENT ME/) }
  end
  describe matches('/tmp/before_last', /^line1\r?\nline2\r?\nline3$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/before_last') do
    it { should have_correct_eol }
    its('size_lines') { should eq 8 }
  end
end
