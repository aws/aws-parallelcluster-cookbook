#
# Append to complex file
#

control 'append_if_no_line_teplate' do
  describe file('/tmp/add_line_file') do
    it { should exist }
    its('content') { should match /^HI THERE I AM STRING$/ }
    its('content') { should match /^last line$/ }
    its('content') { should match %r{^AM I A STRING\?\+\'\"\.\*/\-\\\(\)\{\}\^\$\[\]$} }
  end
  describe file_ext('/tmp/add_line_file') do
    it { should have_correct_eol }
    its('size_lines') { should eq 7 }
  end
end
