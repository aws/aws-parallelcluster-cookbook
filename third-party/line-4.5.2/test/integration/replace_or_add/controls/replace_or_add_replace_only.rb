#
# Replace only

control 'replace_or_add_replace_only' do
  file('/tmp/replace_only') do
    it { should exist }
    its('content') { should_not match /^Penultimate$/ }
  end
  describe matches('/tmp/replace_only', /^Penultimate Replacement$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/replace_only') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end

  file('/tmp/replace_only_nomatch') do
    it { should exist }
    its('content') { should_not match /^Penultimate Replacement$/ }
  end
  describe file_ext('/tmp/replace_only_nomatch') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end
end
