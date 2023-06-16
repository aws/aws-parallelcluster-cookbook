#
# Spec tests for the substitute filter
#

control 'filter_lines_substitute' do
  describe file('/tmp/substitute') do
    it { should exist }
  end
  describe matches('/tmp/substitute', /start_list/) do
    its('count') { should eq 1 }
  end
  describe file_ext('/tmp/substitute') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
