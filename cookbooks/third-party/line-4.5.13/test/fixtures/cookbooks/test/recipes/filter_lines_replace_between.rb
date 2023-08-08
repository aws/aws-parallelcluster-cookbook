#
# Verify the results of using the replace_between filter
#

template '/tmp/replace_between' do
  source 'samplefile.erb'
  sensitive true
  action :create_if_missing
end

filter_lines 'Replace the lines between matches' do
  sensitive false
  path '/tmp/replace_between'
  filters replace_between: [/COMMENT/, /main/, %w(line1 line2 line3)]
end
