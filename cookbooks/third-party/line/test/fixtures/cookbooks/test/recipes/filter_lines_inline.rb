#
# Test an inline filter
#

file '/tmp/inline_nothing' do
  content <<~EOF
    sator
    arepo
    tenet
    opera
    rotas
  EOF
  action :create_if_missing
end

file '/tmp/inline_reverse' do
  content <<~EOF
    sator
    arepo
    tenet
    opera
    rotas
  EOF
  action :create_if_missing
  notifies :edit, 'filter_lines[reverse_line_text]', :immediately
end

filter_lines 'Do nothing' do
  sensitive false
  path '/tmp/inline_nothing'
  filters proc { |current| current }
end

filter_lines 'reverse_line_text' do
  sensitive false
  path '/tmp/inline_reverse'
  filters proc { |current| current.map(&:reverse) }
  action :nothing
end
