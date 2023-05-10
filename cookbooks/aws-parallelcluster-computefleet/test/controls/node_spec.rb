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

control 'tag:testami_node_virtualenv_created' do
  python_version = node['cluster']['python-version']
  virtualenv_path = node['cluster']['node_virtualenv_path']
  min_pip_version = '19.3'

  title "node virtualenv should be created on #{python_version}"
  only_if { !os_properties.redhat_ubi? }

  describe directory(virtualenv_path) do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
  end

  describe bash("#{virtualenv_path}/bin/pip list") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('aws-parallelcluster-node') }
  end

  describe bash("#{virtualenv_path}/bin/python -V") do
    its('exit_status') { should eq 0 }
    its('stdout') { should match /#{python_version}/ }
  end

  describe "pip version should be at least #{min_pip_version}" do
    subject { bash("#{virtualenv_path}/bin/pip -V | awk '{print $2}'") }
    its('exit_status') { should eq 0 }
    its('stdout') { should cmp >= min_pip_version }
  end
end
