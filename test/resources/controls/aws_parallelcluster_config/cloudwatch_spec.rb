control 'tag:config_cloudwatch_configured' do
  title "Check cloudwatch installation files"

  describe file('/usr/local/bin/write_cloudwatch_agent_json.py') do
    it { should exist }
    its('sha256sum') { should eq 'd7c0c151e7b2118c4684eef07463d0644c001fd835d968fa0f9c4e67c55879ab' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
  end

  describe file('/usr/local/etc/cloudwatch_agent_config.json') do
    it { should exist }
    its('sha256sum') { should eq 'dc7a5006fcf635bca2ce65dad6db4df8f6b50db13def391cc5bc65d605a6d9a5' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end

  describe file('/usr/local/etc/cloudwatch_agent_config_schema.json') do
    it { should exist }
    its('sha256sum') { should eq '3380ee721f26c31ac629e5e8573f6e034f890f37d55f46849ada175902815b0c' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end

  describe file('/usr/local/bin/cloudwatch_agent_config_util.py') do
    it { should exist }
    its('sha256sum') { should eq '980b0ba6e5922fe2983d3e866ac970622f59a26a4829b8262466739582176525' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end

  describe 'Check the cloudwatch service'
  if node['cluster']['cw_logging_enabled'] == 'true' || !os_properties.virtualized?
    describe bash("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running") do
      its('exit_status') { should eq 0 }
    end
  end
end
