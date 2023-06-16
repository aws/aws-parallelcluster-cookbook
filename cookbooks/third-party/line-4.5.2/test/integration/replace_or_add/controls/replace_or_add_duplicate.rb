#
# Replace with duplicate line
#

control 'replace_or_add_duplicate' do
  describe file('/tmp/duplicate') do
    it { should exist }
    its('content') { should_not match /^Identical line$/ }
  end
  describe matches('/tmp/duplicate', /^Replace duplicate lines$/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/duplicate') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end

  describe file('/tmp/duplicate_replace_only') do
    it { should exist }
    its('content') { should_not match /^Identical line$/ }
  end
  describe matches('/tmp/duplicate_replace_only', /^Replace duplicate lines$/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/duplicate_replace_only') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end

  describe file('/tmp/duplicate_remove_duplicate') do
    it { should exist }
    its('content') { should_not match /^Identical line$/ }
  end
  describe matches('/tmp/duplicate_remove_duplicate', /^Remove duplicate lines$/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/duplicate_remove_duplicate') do
    it { should have_correct_eol }
    its('size_lines') { should eq 6 }
  end

  describe file('/tmp/duplicate_remove_single_line') do
    it { should exist }
    its('content') { should_not match /^Data line$/ }
  end
  describe matches('/tmp/duplicate_remove_single_line', /^Remove single line$/) do
    its('count') { should eq 1 }
  end
  describe matches('/tmp/duplicate_remove_single_line', /^Identical line$/) do
    its('count') { should eq 2 }
  end
  describe file_ext('/tmp/duplicate_remove_single_line') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end
end
