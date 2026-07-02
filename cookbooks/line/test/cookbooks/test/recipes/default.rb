# frozen_string_literal: true

file '/tmp/line_default_append' do
  content "alpha\n"
  action :create_if_missing
end

append_if_no_line 'append default line' do
  path '/tmp/line_default_append'
  line 'beta'
end

file '/tmp/line_default_replace' do
  content "setting old\n"
  action :create_if_missing
end

replace_or_add 'replace default line' do
  path '/tmp/line_default_replace'
  pattern '^setting '
  line 'setting new'
end

file '/tmp/line_default_delete_lines' do
  content "# remove me\nkeep me\n"
  action :create_if_missing
end

delete_lines 'delete default comments' do
  path '/tmp/line_default_delete_lines'
  pattern '^#'
end

file '/tmp/line_default_list' do
  content "items = one, two\n"
  action :create_if_missing
end

add_to_list 'add default list item' do
  path '/tmp/line_default_list'
  pattern 'items = '
  delim [', ']
  entry 'three'
end

delete_from_list 'delete default list item' do
  path '/tmp/line_default_list'
  pattern 'items = '
  delim [', ']
  entry 'one'
end

file '/tmp/line_default_filter' do
  content "before\n"
  action :create_if_missing
end

filter_lines 'filter default line' do
  path '/tmp/line_default_filter'
  filters after: [/^before$/, ['after']]
end
