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
  # In Ubuntu >20.04 due to environment variable the keyring is placed under home of the user ubuntu with the permission of root
  ubuntu2004 = os_properties.ubuntu2004?
  ubuntu2204 = os_properties.ubuntu2204?
  keyring = (ubuntu2004 || ubuntu2204) && !os_properties.on_docker? ? '--keyring /home/ubuntu/.gnupg/pubring.kbx' : ''
  sudo = os_properties.redhat_on_docker? ? '' : 'sudo'
  describe bash("#{sudo} gpg --list-keys #{keyring}") do
    # Don't check exit status for Ubuntu20 because it returns 2 when executed in the validate phase of a created AMI
    # os_properties cannot be used in the describe block level.  It can be used within an it{} block
    its('exit_status') { should eq 0 } unless ubuntu2004 || ubuntu2204
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
    its('sha256sum') { should eq 'cf304d5c8fa3dd6b5866b28d4a866d5190d7282adeda3adbb39b8bed116ab30c' }
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
    its('sha256sum') { should eq '9019c9235fe54091db4c225fe6be552b229c958ab8a87fa94b5a875545bbfd87' }
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

  describe file('/etc/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.d/file_amazon-cloudwatch-agent.json') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0644' }
  end unless os_properties.on_docker?
end

control 'cloudwatch_logfiles_configuration_loginnode' do
  title "Check CloudWatch configuration generated on login nodes"

  # TODO: add directory service enablement in the context of the test and add the corresponding log files.
  expected_log_files = %w(
    /var/log/cloud-init.log
    /var/log/cloud-init-output.log
    /var/log/supervisord.log
  )
  unexpected_log_files = %w(
    /var/log/messages
    /var/log/syslog
    /var/log/cfn-init.log
    /var/log/chef-client.log
    /var/log/parallelcluster/bootstrap_error_msg
    /var/log/parallelcluster/clustermgtd
    /var/log/parallelcluster/clustermgtd.events
    /var/log/parallelcluster/slurm_resume.events
    /var/log/parallelcluster/compute_console_output.log
    /var/log/parallelcluster/computemgtd
    /var/log/parallelcluster/slurm_resume.log
    /var/log/parallelcluster/slurm_suspend.log
    /var/log/parallelcluster/slurm_fleet_status_manager.log
    /var/log/slurmd.log
    /var/log/slurmctld.log
    /var/log/slurmdbd.log
    /var/log/parallelcluster/pcluster_dcv_authenticator.log
    /var/log/parallelcluster/pcluster_dcv_connect.log
    /var/log/dcv/server.log
    /var/log/dcv/sessionlauncher.log
    /var/log/dcv/agent.*.log
    /var/log/dcv/dcv-xsession.*.log
    /var/log/dcv/Xdcv.*.log
    /var/log/parallelcluster/slurm_health_check.log
    /var/log/parallelcluster/slurm_health_check.events
    /var/log/parallelcluster/clusterstatusmgtd
  )

  describe file('/etc/amazon/amazon-cloudwatch-agent/amazon-cloudwatch-agent.d/file_amazon-cloudwatch-agent.json') do
    expected_log_files.each do |log_file|
      its('content') { should include(log_file) }
    end
    unexpected_log_files.each do |log_file|
      its('content') { should_not include(log_file) }
    end
  end unless os_properties.on_docker?
end
