#
# Verify the results of using the before filter
#

template '/tmp/before' do
  source 'samplefile.erb'
  sensitive true
  action :create_if_missing
end

template '/tmp/before_first' do
  source 'samplefile.erb'
  sensitive true
  action :create_if_missing
end

template '/tmp/before_last' do
  source 'samplefile.erb'
  sensitive true
  action :create_if_missing
end

filter_lines 'Insert lines before match' do
  path '/tmp/before'
  sensitive false
  filters before: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3)]
end

filter_lines 'Insert lines before match' do
  path '/tmp/before_first'
  sensitive false
  filters before: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3), :first]
end

filter_lines 'Insert lines last match' do
  path '/tmp/before_last'
  sensitive false
  filters before: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3), :last]
end
