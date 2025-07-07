#
# Test for lists with 1 delimitor ,
#

control 'add_to_list_1d' do
  describe file('/tmp/1d') do
    it { should exist }
    its('content') { should match /^empty_list=newentry$/ }
    its('content') { should match /^People to call: Joe, Bobby, Karen, Harry$/ }
  end
  describe file_ext('/tmp/1d') do
    it { should have_correct_eol }
    its('size_lines') { should eq 20 }
  end
end
