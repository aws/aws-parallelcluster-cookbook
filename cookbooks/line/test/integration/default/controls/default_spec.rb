# frozen_string_literal: true

title 'Default line resource workflow'

control 'line-default-01' do
  impact 1.0
  title 'The default suite applies line resources'

  describe file('/tmp/line_default_append') do
    its('content') { should match(/^alpha$/) }
    its('content') { should match(/^beta$/) }
  end

  describe file('/tmp/line_default_replace') do
    its('content') { should match(/^setting new$/) }
    its('content') { should_not match(/^setting old$/) }
  end

  describe file('/tmp/line_default_delete_lines') do
    its('content') { should match(/^keep me$/) }
    its('content') { should_not match(/^# remove me$/) }
  end

  describe file('/tmp/line_default_list') do
    its('content') { should match(/^items = two, three$/) }
  end

  describe file('/tmp/line_default_filter') do
    its('content') { should match(/^before$/) }
    its('content') { should match(/^after$/) }
  end
end
