control 'tag:install_cloudwatch_installation_files' do
  title "Check cloudwatch installation files"

  package_extension = os_properties.debian_family? ? 'deb' : 'rpm'

  signature_path = "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.#{package_extension}.sig"

  describe file(signature_path) do
    it { should exist }
  end

  describe file("#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.#{package_extension}") do
    it { should exist }
  end

  describe 'Check the presence of the cloudwatch package gpg key'
  # In Ubuntu 20.04 due to environment variable the keyring is placed under home of the user ubuntu with the permission of root
  ubuntu2004 = os_properties.ubuntu2004?
  keyring = os_properties.ubuntu2004? && !os_properties.on_docker? ? '--keyring /home/ubuntu/.gnupg/pubring.kbx' : ''
  sudo = os_properties.redhat_ubi? ? '' : 'sudo'
  describe bash("#{sudo} gpg --list-keys #{keyring}") do
    # Don't check exit status for Ubuntu20 because it returns 2 when executed in the validate phase of a created AMI
    its('exit_status') { should eq 0 } unless ubuntu2004
    its('stdout') { should match /3B789C72/ }
    its('stdout') { should match /Amazon CloudWatch Agent/ }
  end
end

control 'tag:install_cloudwatch_packaged_installed' do
  title "Check if cloudwatch package is installed"
  describe package('amazon-cloudwatch-agent') do
    it { should be_installed }
  end
end

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
    # No sha256sum check since the file is modified runtime by cloudwatch_agent_config_util.py
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
  if node['cluster']['cw_logging_enabled'] == 'true' && !os_properties.on_docker?
    describe bash("/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running") do
      its('exit_status') { should eq 0 }
    end
  end
end
