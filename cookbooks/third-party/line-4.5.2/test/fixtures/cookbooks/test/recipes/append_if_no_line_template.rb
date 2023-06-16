#
# Append to complex file
#

template '/tmp/add_line_file' do
  source 'samplefile.erb'
  action :create_if_missing
end

append_if_no_line 'Add a line' do
  path '/tmp/add_line_file'
  line 'HI THERE I AM STRING'
end

append_if_no_line 'with special chars' do
  path '/tmp/add_line_file'
  line 'AM I A STRING?+\'".*/-\(){}^$[]'
end
