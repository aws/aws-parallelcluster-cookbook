#
# Test replace_or_add with the replace_only flag set to true
#

template '/tmp/replace_only' do
  source 'text_file.erb'
  action :create_if_missing
end

template '/tmp/replace_only_nomatch' do
  source 'text_file.erb'
  action :create_if_missing
end

replace_or_add 'replace_only' do
  path '/tmp/replace_only'
  pattern 'Penultimate'
  line 'Penultimate Replacement'
  replace_only true
end

replace_or_add 'replace_only_nomatch' do
  path '/tmp/replace_only_nomatch'
  pattern 'Does not match'
  line 'Penultimate Replacement'
  replace_only true
end
