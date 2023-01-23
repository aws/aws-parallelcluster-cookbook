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

control 'sudo' do
  title 'Install sudo package and prepare sudoers file'

  describe package('sudo') do
    it { should be_installed }
  end

  describe file('/etc/sudoers.d/99-parallelcluster-secure-path') do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('content') { should match(%r{Defaults secure_path = /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin}) }
  end
end
