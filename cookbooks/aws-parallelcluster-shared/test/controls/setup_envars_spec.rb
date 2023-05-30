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

# directories = %w(/usr/local/sbin /usr/local/bin /sbin /bin /usr/sbin /usr/bin /opt/aws/bin)
directories = %w(/usr/local/sbin /usr/local/bin /sbin /bin /usr/sbin /usr/bin)

control 'tag:config_setup_envars_system_path_contains_required_directories' do
  title 'System path contains required directories'

  describe file('/etc/profile.d/path.sh') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  path = bash('. /etc/profile.d/path.sh; echo ${PATH}').stdout.strip().split(':')
  describe "System path #{path}" do
    subject { path }
    directories.each do |dir|
      it { should include dir }
    end
  end
end

control "tag:config_setup_envars_paths_for_notable_users_contain_required_directories" do
  title "Path for notable users contain required directories"

  %W(root #{node['cluster']['cluster_admin_user']} #{node['cluster']['slurm']['user']}).each do |user|
    path = bash("sudo runuser -u #{user} -- . /etc/profile.d/path.sh; echo $PATH").stdout.strip().split(':')

    describe "Path #{path}", :sensitive do
      describe "for user #{user}" do
        subject { path }
        directories.each do |dir|
          it { should include dir }
        end
      end
    end
  end
end
