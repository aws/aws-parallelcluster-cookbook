
#
# Spec tests for the nonstatdard properties
#

control 'filter_lines_other_props' do
  describe file('/tmp/missingfile') do
    it { should_not exist }
  end

  describe file('/tmp/emptyfile') do
    it { should exist }
    its('size') { should eq 0 }
  end

  describe file('/tmp/safe_bypass') do
    it { should exist }
  end
  describe matches('/tmp/safe_bypass', /^line1$/) do
    its('count') { should eq 3 }
  end
  describe file_ext('/tmp/safe_bypass') do
    it { should have_correct_eol }
    its('size_lines') { should eq 3 }
  end
end
