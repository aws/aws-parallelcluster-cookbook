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

control 'path_contains_required_directories' do
  title 'System path contains required directories'

  describe file('/etc/profile.d/path.sh') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  path = command('source /etc/profile.d/path.sh; echo ${PATH}').stdout.strip().split(':')
  describe "System path #{path}" do
    subject { path }
    it { should include '/usr/local/bin', '/usr/local/sbin' }
    it { should include '/sbin', '/bin' }
    it { should include '/usr/sbin', '/usr/bin' }
    it { should include '/opt/aws/bin' }
  end
end
