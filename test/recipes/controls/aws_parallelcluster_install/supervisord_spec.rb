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

control 'supervisord_config_created' do
  title 'supervisord configuration created under /etc'

  describe file('/etc/supervisord.conf') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match 'files = /etc/parallelcluster/parallelcluster_supervisord.conf' }
  end
end

control 'supervisord_service_set_up' do
  title 'supervisord is set up'

  describe file('/etc/systemd/system/supervisord.service') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end
end

control 'tag:config_supervisord_runs_as_root' do
  describe processes('supervisord') do
    its('count') { should eq 1 }
    its('users') { should eq ['root'] }
  end
end

control 'tag:config_supervisord_service_is_enabled' do
  describe service('supervisord') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end
