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

python_version = '3.9.16'
cfn_python_version = '3.7.16'
base_dir = "/opt/parallelcluster"
pyenv_dir = "#{base_dir}/pyenv"

control 'awsbatch_virtualenv_created' do
  title "awsbatch virtualenv should be created on #{python_version}"
  only_if { !os_properties.redhat_ubi? }

  describe directory("#{pyenv_dir}/versions/#{python_version}/envs/awsbatch_virtualenv") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'cookbook_virtualenv_created' do
  title "cookbook virtualenv should be created on #{python_version}"
  only_if { !os_properties.redhat_ubi? }

  describe directory("#{pyenv_dir}/versions/#{python_version}/envs/cookbook_virtualenv") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'node_virtualenv_created' do
  title "node virtualenv should be created on #{python_version}"
  only_if { !os_properties.redhat_ubi? }

  describe directory("#{pyenv_dir}/versions/#{python_version}/envs/cookbook_virtualenv") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end
end

control 'cfnbootstrap_virtualenv_created' do
  title "cfnbootstrap virtualenv should be created on #{cfn_python_version}"
  only_if { !os_properties.redhat_ubi? }

  describe directory("#{pyenv_dir}/versions/#{cfn_python_version}/envs/cfn_bootstrap_virtualenv") do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  desc "aws-cfn-bootstrap should be installed on cfnbootstrap virtualenv"
  describe bash("#{pyenv_dir}/versions/#{cfn_python_version}/envs/cfn_bootstrap_virtualenv/bin/pip list") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('aws-cfn-bootstrap') }
  end

  desc "cfnbootstrap virtualenv bin dir should be added to the PATH"
  describe file('/etc/profile.d/pcluster.sh') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should match "PATH=\\$PATH:#{pyenv_dir}/versions/#{cfn_python_version}/envs/cfn_bootstrap_virtualenv/bin" }
  end
end
