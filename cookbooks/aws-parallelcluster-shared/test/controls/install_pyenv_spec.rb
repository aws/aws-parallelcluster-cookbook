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

control 'default_pyenv_installed' do
  title 'pyenv should be installed'

  only_if { !os_properties.redhat_on_docker? }

  describe command("#{node['cluster']['system_pyenv_root']}/bin/pyenv") do
    it { should exist }
  end

  describe bash("#{node['cluster']['system_pyenv_root']}/bin/pyenv global") do
    its('exit_status') { should eq(0) }
    its('stdout')      { should match('system') }
  end
end
