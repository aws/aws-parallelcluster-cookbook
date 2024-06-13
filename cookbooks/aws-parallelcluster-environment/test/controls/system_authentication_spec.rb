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

control 'tag:install_system_authentication_packages_installed' do
  title 'Check that system authentication packages are installed correctly'

  packages = %w(sssd sssd-tools sssd-ldap)

  if os_properties.redhat8?
    packages.append("authselect")
    packages.append("oddjob-mkhomedir")
  end

  packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end unless os_properties.redhat_on_docker?
end

control 'tag:config_system_authentication_services_enabled' do
  title 'Check that system authentication services are enabled and running'

  only_if { !os_properties.on_docker? }
  only_if { node['cluster']["directory_service"]["enabled"] != 'false' }
  only_if { node['cluster']['node_type'] != 'ComputeFleet' || node['cluster']['directory_service']['disabled_on_compute_nodes'] != 'true' }

  services = %w(sssd)

  if os.redhat?
    services.append("oddjobd")
  end

  services.each do |service|
    describe service(service) do
      it { should be_installed }
      it { should be_enabled }
    end
  end
end

control 'tag:config_system_authentication_configured' do
  title 'Check that system authentication is configured correctly'

  only_if { !os_properties.on_docker? }
  only_if { node['cluster']["directory_service"]["enabled"] != 'false' }
  only_if { node['cluster']['node_type'] != 'ComputeFleet' || node['cluster']['directory_service']['disabled_on_compute_nodes'] != 'true' }

  describe 'Check NSS and PAM to use SSSD for system authentication and identity information'
  if os_properties.redhat?
    describe bash("authselect current") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /Profile ID: sssd/ }
      its('stdout') { should match /with-mkhomedir/ }
    end unless os_properties.redhat_on_docker?

  elsif os_properties.centos7? || os_properties.alinux2?

    describe bash("authconfig --test") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /nss_sss is enabled by default/ }
      its('stdout') { should match /pam_sss is enabled by default/ }
      its('stdout') { should match /pam_mkhomedir or pam_oddjob_mkhomedir is enabled/ }
    end

  end
end
