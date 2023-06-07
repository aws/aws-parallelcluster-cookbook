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

control 'tag:install_pmix_installed' do
  title 'Checks PMIx has been installed'

  describe file("/opt/pmix") do
    it { should exist }
    it { should be_directory }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end unless os_properties.redhat_ubi?
end

control 'tag:install_pmix_library_shared' do
  title 'Checks PMIx shared library is part of the runtime search path'

  describe file("/etc/ld.so.conf.d/pmix.conf") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') do
      should match('/opt/pmix/lib')
    end
  end unless os_properties.redhat_ubi?
end
