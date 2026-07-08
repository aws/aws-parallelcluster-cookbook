# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

control 'tag:install_pcluster_diag_installed' do
  title 'pcluster-diag source is staged in the expected location and its wrapper is installed on PATH'

  only_if { !os_properties.redhat_on_docker? }

  source_dir = "#{node['cluster']['sources_dir']}/pcluster-diag"

  describe directory(source_dir) do
    it { should exist }
  end

  # The tool is run directly from source, so its package must be present under the staged source dir.
  describe file("#{source_dir}/pcluster_diag/cli.py") do
    it { should exist }
  end

  describe file('/usr/local/bin/pcluster-diag') do
    it { should exist }
    it { should be_executable }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('mode') { should cmp '0744' }
  end
end

control 'tag:install_pcluster_diag_runnable' do
  title 'pcluster-diag is discoverable on PATH and runnable as root'

  only_if { !os_properties.redhat_on_docker? }

  describe 'pcluster-diag resolves on the root PATH to the wrapper' do
    subject { bash("sudo su - -c 'which pcluster-diag'") }
    its('exit_status') { should eq 0 }
    its('stdout') { should match(%r{^/usr/local/bin/pcluster-diag$}) }
  end

  describe 'pcluster-diag runs as root' do
    subject { bash("sudo su - -c 'pcluster-diag --version'") }
    its('exit_status') { should eq 0 }
  end
end
