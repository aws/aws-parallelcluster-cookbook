control 'cloudwatch_installation_files' do
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
  keyring = os_properties.ubuntu2004? && !os_properties.virtualized? ? '--keyring /home/ubuntu/.gnupg/pubring.kbx' : ''
  sudo = os_properties.redhat_ubi? ? '' : 'sudo'
  describe bash("#{sudo} gpg --list-keys #{keyring}") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /3B789C72/ }
    its('stdout') { should match /Amazon CloudWatch Agent/ }
  end
end

control 'cloudwatch_packaged_installed' do
  title "Check if cloudwatch package is installed"
  describe package('amazon-cloudwatch-agent') do
    it { should be_installed }
  end
end
