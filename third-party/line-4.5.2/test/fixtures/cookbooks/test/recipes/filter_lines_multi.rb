#
# Test combinations of filters and edge cases
#

template '/tmp/multiple_filters' do
  source 'samplefile.erb'
  sensitive true
  action :create_if_missing
end

filter_lines 'Multiple before and after match' do
  path '/tmp/multiple_filters'
  sensitive false
  filters(
    [
      # insert lines before the last match
      { before: [/^COMMENT ME|^HELLO/, %w(line1 line2 line3), :last] },
      # insert lines after the last match
      { after:  [/^COMMENT ME|^HELLO/, %w(line1 line2 line3), :last] },
      # delete comment lines
      proc { |current| current.select { |line| line !~ /^#/ } },
    ]
  )
end
