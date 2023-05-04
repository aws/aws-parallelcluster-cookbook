#
# Test the replace_or_add resource with duplicate lines
#

template '/tmp/duplicate' do
  source 'text_file.erb'
  action :create_if_missing
end

template '/tmp/duplicate_replace_only' do
  source 'text_file.erb'
  action :create_if_missing
end

template '/tmp/duplicate_remove_duplicate' do
  source 'text_file.erb'
  action :create_if_missing
end

template '/tmp/duplicate_remove_single_line' do
  source 'text_file.erb'
  action :create_if_missing
end

replace_or_add 'duplicate' do
  path '/tmp/duplicate'
  pattern 'Identical line'
  line 'Replace duplicate lines'
end

replace_or_add 'duplicate_replace_only' do
  path '/tmp/duplicate_replace_only'
  replace_only true
  pattern 'Identical line'
  line 'Replace duplicate lines'
end

replace_or_add 'duplicate_remove_duplicate' do
  path '/tmp/duplicate_remove_duplicate'
  replace_only true
  pattern 'Identical line'
  line 'Remove duplicate lines'
  remove_duplicates true
end

replace_or_add 'duplicate_remove_single line' do
  path '/tmp/duplicate_remove_single_line'
  pattern 'Data line'
  line 'Remove single line'
  remove_duplicates true
end
