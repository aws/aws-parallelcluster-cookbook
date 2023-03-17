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

control 'admin_user_correctly_defined' do
  describe user(node['cluster']['cluster_admin_user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['cluster_admin_user_id'] }
    its('gid') { should eq node['cluster']['cluster_admin_group_id'] }
    # "AWS ParallelCluster Admin user"
  end

  describe group(node['cluster']['cluster_admin_group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['cluster_admin_group_id'] }
  end
end

control 'slurm_user_correctly_defined' do
  only_if { node['cluster']['scheduler'] == 'slurm' }

  describe user(node['cluster']['slurm']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['slurm']['user_id'] }
    its('gid') { should eq node['cluster']['slurm']['group_id'] }
    # 'slurm user'
  end

  describe group(node['cluster']['slurm']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['slurm']['group_id'] }
  end
end

control 'munge_user_correctly_defined' do
  only_if { node['cluster']['scheduler'] == 'slurm' }

  describe user(node['cluster']['munge']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['munge']['user_id'] }
    its('gid') { should eq node['cluster']['munge']['group_id'] }
    its('shell') { should eq '/sbin/nologin' }
    # 'munge user'
  end

  describe group(node['cluster']['munge']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['munge']['group_id'] }
  end
end

control 'dcv_external_authenticator_user_correctly_defined' do
  only_if { node['conditions']['dcv_supported'] }

  describe user(node['cluster']['dcv']['authenticator']['user']) do
    it { should exist }
    its('uid') { should eq node['cluster']['dcv']['authenticator']['user_id'] }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
    # 'NICE DCV External Authenticator user'
  end

  describe group(node['cluster']['dcv']['authenticator']['group']) do
    it { should exist }
    its('gid') { should eq node['cluster']['dcv']['authenticator']['group_id'] }
  end
end

control 'cluster_user_can_sudo' do
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
