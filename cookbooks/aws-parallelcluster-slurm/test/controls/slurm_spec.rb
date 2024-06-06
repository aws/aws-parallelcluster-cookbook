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

slurm_user = 'slurm'
slurm_group = slurm_user
slurm_share_group = 'pcluster-slurm-share'
slurm_license_path = '/opt/parallelcluster/licenses/slurm'
slurm_library_folder = '/opt/slurm/lib/slurm'
pcluster_admin = 'pcluster-admin'
pcluster_admin_group = pcluster_admin

control 'tag:install_slurm_installed' do
  title 'Checks slurm has been installed'

  only_if { !os_properties.redhat_on_docker? }

  describe file("/opt/slurm") do
    it { should exist }
    it { should be_directory }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'tag:install_slurm_user_and_group_created' do
  title 'Check slurm user and group exist and are properly configured'

  describe group(slurm_group) do
    it { should exist }
  end

  describe group(slurm_share_group) do
    it { should exist }
  end

  describe user(slurm_user) do
    it { should exist }
    its('groups') { should eq [slurm_group, slurm_share_group] }
  end

  describe user(pcluster_admin) do
    it { should exist }
    its('groups') { should eq [pcluster_admin_group, slurm_share_group] }
  end
end

control 'tag:install_slurm_licence_configured' do
  title 'Checks slurm licences folder has the required files'

  only_if { !os_properties.redhat_on_docker? }

  describe file(slurm_license_path) do
    it { should exist }
    it { should be_directory }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_license_path}/COPYING") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_license_path}/DISCLAIMER") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_license_path}/LICENSE.OpenSSL") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_license_path}/README.rst") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'tag:install_slurm_shared_libraries_compiled' do
  title 'Checks that all required slurm shared libraries were compiled'

  only_if { !os_properties.redhat_on_docker? }

  describe file("#{slurm_library_folder}/accounting_storage_mysql.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_library_folder}/auth_jwt.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_library_folder}/auth_munge.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_library_folder}/mpi_pmix_v5.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'tag:install_slurm_library_shared' do
  title 'Checks slurm shared library is part of the runtime search path'

  only_if { !os_properties.redhat_on_docker? }

  describe file("/etc/ld.so.conf.d/slurm.conf") do
    it { should exist }
    its('mode') { should cmp '0744' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') do
      should match('/opt/slurm/lib/')
    end
  end
end

control 'tag:install_slurm_pam_slurm_adopt_module_installed' do
  title "Check that pam_slurm_adopt has been built and installed"
  only_if { !os_properties.redhat_on_docker? }

  lib_security_folder = '/lib/security'
  if os.redhat?
    lib_security_folder = '/lib64/security'
  end

  describe file("#{lib_security_folder}/pam_slurm_adopt.a") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{lib_security_folder}/pam_slurm_adopt.la") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{lib_security_folder}/pam_slurm_adopt.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'tag:install_slurm_lua_support_libraries_compiled' do
  title 'Checks that all slurm libraries required for lua were compiled'

  only_if { !os_properties.redhat_on_docker? }

  describe file("#{slurm_library_folder}/burst_buffer_lua.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_library_folder}/cli_filter_lua.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_library_folder}/job_submit_lua.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe file("#{slurm_library_folder}/jobcomp_lua.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end
