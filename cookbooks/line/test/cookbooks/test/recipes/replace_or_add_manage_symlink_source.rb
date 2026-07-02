# frozen_string_literal: true

file '/tmp/replace_or_add_symlink_target' do
  content "keep me\n"
  action :create_if_missing
end

link '/tmp/replace_or_add_symlink' do
  to '/tmp/replace_or_add_symlink_target'
end

replace_or_add 'replace_or_add_manage_symlink_source_true' do
  path '/tmp/replace_or_add_symlink'
  pattern '^keep me$'
  line 'updated through target'
  manage_symlink_source true
end

file '/tmp/replace_or_add_manage_symlink_source_false' do
  content "before explicit false\n"
  action :create_if_missing
end

replace_or_add 'replace_or_add_manage_symlink_source_false' do
  path '/tmp/replace_or_add_manage_symlink_source_false'
  pattern '^before explicit false$'
  line 'updated with explicit false'
  manage_symlink_source false
end
