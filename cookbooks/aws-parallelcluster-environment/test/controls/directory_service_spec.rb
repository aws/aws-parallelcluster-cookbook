# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'sssd_configured_correctly' do
  title "Check SSSd is correctly configured"

  describe file('/etc/sssd/sssd.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
    # Mandatory properties
    its('content') { should match /id_provider = ldap/ }
    its('content') { should match /ldap_schema = AD/ }
    # Mandatory properties that can be overwritten by DirectoryService/AdditionalSssdConfigs
    its('content') { should match /ldap_default_bind_dn = cn=ReadOnlyUser,ou=Users,ou=CORP,dc=corp,dc=something,dc=com/ }
    its('content') { should match /ldap_default_authtok = fake-secret/ }
    its('content') { should match /ldap_tls_reqcert = never/ }
    # Optional properties that can be overwritten by DirectoryService/AdditionalSssdConfigs
    its('content') { should match /cache_credentials = True/ }
    its('content') { should match /ldap_id_mapping = True/ }
    its('content') { should match /use_fully_qualified_names = False/ }
    # Optional properties that are meant to be set via dedicated cluster config properties
    its('content') { should match %r{ldap_tls_cacert = /path/to/domain-certificate\.crt} }
    its('content') { should match /ldap_access_filter = filter-string/ }
    # Optional properties that are meant to be set via DirectoryService/AdditionalSssdConfigs
    its('content') { should match /debug_level = 0x1ff/ }
  end unless os_properties.on_docker?

  shared_dirs = %w(shared shared_login_nodes)
  shared_dirs.each do |shared|
    describe directory("/opt/parallelcluster/#{shared}/directory_service") do
      it { should exist }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '0600' }
    end

    describe file("/opt/parallelcluster/#{shared}/directory_service/sssd.conf") do
      it { should exist }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
      its('mode') { should cmp '0600' }
    end unless os_properties.on_docker?
  end

  desc 'Check SSH password authentication is enabled on head node'
  describe file('/etc/ssh/sshd_config') do
    it { should exist }
    its('content') { should match /PasswordAuthentication yes/ }
  end unless os_properties.on_docker?

  scripts_dir = "/opt/parallelcluster/scripts"
  describe directory("#{scripts_dir}/directory_service") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0744' }
  end

  shared_dir = "/opt/parallelcluster/shared/directory_service"
  describe file("#{scripts_dir}/directory_service/update_directory_service_password.sh") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0744' }
    its('content') { should match /SECRET_ARN="arn:aws:secretsmanager:eu-west-1:123456789:secret:a-secret-name"/ }
    its('content') { should match %r{SSSD_SHARED_CONFIG_FILE="#{shared_dir}/sssd.conf"} }
  end

  describe file("#{scripts_dir}/generate_ssh_key.sh") do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0755' }
    its('content') { should match /ssh-keygen -q -t ed25519/ }
  end

  pam_services = %w(sudo su sshd)
  pam_services.each do |pam_service|
    describe file("/etc/pam.d/#{pam_service}") do
      it { should exist }
      its('content') { should match %r{session\s+optional\s+pam_exec\.so\s+log=/var/log/parallelcluster/pam_ssh_key_generator\.log} }
    end
  end

  %w(sssd sshd).each do |daemon|
    describe service(daemon) do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
  end
end

control 'sssd_configured_correctly_login_nodes' do
  title "Check SSSd is correctly configured in LoginNodes"

  desc 'Check SSH password authentication is enabled on login node'
  describe file('/etc/ssh/sshd_config') do
    it { should exist }
    its('content') { should match /PasswordAuthentication yes/ }
  end unless os_properties.on_docker?

  describe file('/etc/sssd/sssd.conf') do
    it { should exist }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0600' }
  end unless os_properties.on_docker?

  %w(sssd sshd).each do |daemon|
    describe service(daemon) do
      it { should be_installed }
      it { should be_enabled }
      it { should be_running }
    end
  end

  pam_services = %w(sudo su sshd)
  pam_services.each do |pam_service|
    describe file("/etc/pam.d/#{pam_service}") do
      it { should exist }
      its('content') { should match %r{session\s+optional\s+pam_exec\.so\s+log=/var/log/parallelcluster/pam_ssh_key_generator\.log} }
    end
  end
end
