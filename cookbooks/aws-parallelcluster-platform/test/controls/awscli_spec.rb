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
  title 'only awscli v2 should be installed, system-wide'

  only_if { !os_properties.redhat_on_docker? }

  describe file('/usr/local/bin/aws') do
    it { should exist }
  end

  describe bash('/usr/local/bin/aws --version') do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match(%r{^aws-cli/2\.}) }
  end

  # AWS CLI v2 is not published on PyPI, so any awscli package in the virtualenv would be v1.
  describe bash("#{node['cluster']['cookbook_virtualenv_path']}/bin/pip list") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should_not match('awscli') }
  end

  describe file("#{node['cluster']['cookbook_virtualenv_path']}/bin/aws") do
    it { should_not exist }
  end
end

control 'tag:testami_awscli_can_run_as_cluster_user_and_as_root' do
  only_if { !os_properties.redhat_on_docker? }

  describe "aws cli can run as cluster default user #{node['cluster']['cluster_user']}" do
    subject { bash("sudo su - #{node['cluster']['cluster_user']} -c 'aws --version'") }
    its('exit_status') { should eq 0 }
  end unless os_properties.on_docker?

  describe 'aws cli can run as root' do
    subject { bash("sudo su - -c 'aws --version'") }
    its('exit_status') { should eq 0 }
  end
end
