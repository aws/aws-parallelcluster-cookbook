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

control 'system_authentication_packages_installed' do
  title 'Check that system authentication packages are installed correctly'

  packages = %w(sssd sssd-tools sssd-ldap)
  packages.each do |pkg|
    describe package(pkg) do
      it { should be_installed }
    end
  end unless os_properties.redhat_ubi?
end

control 'system_authentication_configured' do
  title 'Check that system authentication is configured correctly'

  describe 'Check NSS and PAM to use SSSD for system authentication and identity information'
  if os_properties.redhat8?

    describe bash("authselect current") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /Profile ID: sssd/ }
      its('stdout') { should match /with-mkhomedir/ }
    end unless os_properties.redhat_ubi?

  elsif os_properties.centos7? || os_properties.alinux2?

    describe bash("authconfig --test") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /nss_sss is enabled by default/ }
      its('stdout') { should match /pam_sss is enabled by default/ }
      its('stdout') { should match /pam_mkhomedir or pam_oddjob_mkhomedir is enabled/ }
    end

  end
end
