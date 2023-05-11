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

control 'sudo_configured' do
  title 'Check that sudo has been configured'

  describe file('/etc/sudoers.d/99-parallelcluster-user-tty') do
    it { should exist }
    its('mode') { should cmp '0600' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end

  describe file('/etc/parallelcluster/parallelcluster_supervisord.conf') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end
end

control 'tag:config_cluster_user_can_sudo' do
  only_if { !os_properties.on_docker? }

  if os_properties.debian_family?
    describe node['cluster']['cluster_user'] do
      it { should eq 'ubuntu' }
    end
  end

  %W(root #{node['cluster']['cluster_user']}).each do |user|
    describe command("sudo runuser -u #{user} -- sudo -n aws --version") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match /^aws/ }
    end
  end
end
