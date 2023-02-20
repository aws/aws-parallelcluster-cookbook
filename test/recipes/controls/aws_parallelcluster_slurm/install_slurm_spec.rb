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
slurm_license_path = '/opt/parallelcluster/licenses/slurm'
slurm_library_folder = '/opt/slurm/lib/slurm'

control 'slurm_installed' do
  title 'Checks slurm has been installed'

  only_if { !os_properties.redhat_ubi? }

  describe file("/opt/slurm") do
    it { should exist }
    it { should be_directory }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'slurm_user_and_group_created' do
  title 'Check slurm user and group exist and are properly configured'

  describe group(slurm_group) do
    it { should exist }
  end

  describe user(slurm_user) do
    it { should exist }
    its('group') { should eq slurm_group }
  end
end

control 'slurm_licence_configured' do
  title 'Checks slurm licences folder has the required files'

  only_if { !os_properties.redhat_ubi? }

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

control 'slurm_shared_libraries_compiled' do
  title 'Checks that all required slurm shared libraries were compiled'

  only_if { !os_properties.redhat_ubi? }

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

  describe file("#{slurm_library_folder}/mpi_pmix_v3.so") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'slurm_library_shared' do
  title 'Checks slurm shared library is part of the runtime search path'

  only_if { !os_properties.redhat_ubi? }

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
