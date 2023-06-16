#
# Test missing file and unsafe behavior
#

filter_lines 'Missing file ok' do
  path '/tmp/missing'
  filters after: [/^COMMENT ME|^HELLO/, "line1\nline2\nline3\n"]
end

filter_lines 'Missing file fails' do
  path '/tmp/missing'
  ignore_missing false
  ignore_failure true
  filters after: [/^COMMENT ME|^HELLO/, "line1\nline2\nline3\n"]
end

file '/tmp/emptyfile' do
  content ''
  action :create_if_missing
end

filter_lines 'Empty file' do
  path '/tmp/emptyfile'
  filters after: [/^COMMENT ME|^HELLO/, "line1\nline2\nline3\n"]
end

# Without safe mode lines can be inserted after every run
file '/tmp/safe_bypass' do
  content 'line1'
  action :create_if_missing
  notifies :edit, 'filter_lines[Bypass safe]', :immediately
end

filter_lines 'Bypass safe' do
  sensitive false
  path '/tmp/safe_bypass'
  safe false
  filters after: [/line1/, ['line1'], :last]
  action :nothing
  notifies :edit, 'filter_lines[Bypass safe again]', :immediately
end

filter_lines 'Bypass safe again' do
  sensitive false
  path '/tmp/safe_bypass'
  safe false
  filters after: [/line1/, ['line1'], :last]
  action :nothing
end
