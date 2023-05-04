#
# Verify the results of using the after filter
#

template '/tmp/after' do
  source 'samplefile.erb'
  action :create_if_missing
end

template '/tmp/after_text' do
  source 'samplefile.erb'
  action :create_if_missing
end

template '/tmp/after_first' do
  source 'samplefile.erb'
  action :create_if_missing
end
template '/tmp/after_last' do
  source 'samplefile.erb'
  action :create_if_missing
end

filter_lines 'Insert lines after match' do
  sensitive false
  path '/tmp/after'
  filters after: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3)]
end

filter_lines 'Insert lines after match - text' do
  sensitive false
  path '/tmp/after_text'
  filters after: [/^COMMENT ME|^HELLO/, "line1\nline2\nline3\n"]
end

filter_lines 'Insert lines after first match' do
  sensitive false
  path '/tmp/after_first'
  filters after: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3), :first]
end

filter_lines 'Insert lines after last match' do
  sensitive false
  path '/tmp/after_last'
  filters after: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3), :last]
end
