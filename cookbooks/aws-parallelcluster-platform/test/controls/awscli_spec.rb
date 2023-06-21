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

control 'tag:install_awscli_installed' do
  title 'awscli package should be installed in cookbook virtualenv'

  only_if { !os_properties.redhat_on_docker? }

  describe bash("#{node['cluster']['cookbook_virtualenv_path']}/bin/pip list") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('awscli') }
  end

  describe file('/usr/local/bin/aws') do
    it { should exist }
  end
end

control 'tag:testami_awscli_can_run_as_cluster_user_and_as_root' do
  only_if { !os_properties.redhat_on_docker? }
  virtualenv_path = node['cluster']['cookbook_virtualenv_path']

  describe "aws cli can run as cluster default user #{node['cluster']['cluster_user']}" do
    subject { bash("sudo su - #{node['cluster']['cluster_user']} -c 'aws --version'") }
    its('exit_status') { should eq 0 }
  end unless os_properties.on_docker?

  describe 'aws cli can run as root' do
    subject { bash("sudo su - -c 'aws --version'") }
    its('exit_status') { should eq 0 }
  end

  describe 'aws cli can run as root in cookbook virtualenv' do
    subject { bash("#{virtualenv_path}/bin/aws --version") }
    its('exit_status') { should eq 0 }
  end
end

control 'tag:config_awscli_runs_in_all_regions' do
  only_if { node['cluster']['scheduler'] == 'awsbatch' }
  regions = bash("#{node['cluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region #{node['cluster']['region']} --query \"Regions[].{Name:RegionName}\" --output text")
            .stdout.split(/\n+/)
  regions.each do |region|
    describe "check aws cli runs in #{region}" do
      subject { bash("#{node['cluster']['cookbook_virtualenv_path']}/bin/aws ec2 describe-regions --region #{region}") }
      its('exit_status') { should eq 0 }
    end
  end
end
