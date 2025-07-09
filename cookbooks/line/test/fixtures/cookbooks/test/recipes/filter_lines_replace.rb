#
# Verify the results of using the replace filter
#

template '/tmp/replace' do
  source 'samplefile.erb'
  sensitive true
  action :create_if_missing
end

filter_lines 'Replace the matched line' do
  sensitive false
  path '/tmp/replace'
  filters replace: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3)]
end
