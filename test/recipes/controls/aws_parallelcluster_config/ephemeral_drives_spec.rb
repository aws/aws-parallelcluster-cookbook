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

control 'ephemeral_drives_service' do
  title 'Check ephemeral drives service is running'

  only_if { !os_properties.virtualized? }

  describe service('setup-ephemeral') do
    it { should be_installed }
    it { should be_enabled }
  end

  # TODO: add test to see drivers are mounted
end

control 'ephemeral_drives_with_name_clashing_not_mounted' do
  title 'Check ephemeral drives are not mounted when there is name clashing with reserved names'

  only_if { !os_properties.virtualized? }

  describe service('setup-ephemeral') do
    it { should be_installed }
    it { should_not be_enabled }
    it { should_not be_running }
  end

  describe bash('systemctl show setup-ephemeral.service -p ActiveState | grep "=inactive"') do
    its(:exit_status) { should eq 0 }
  end

  describe bash('systemctl show setup-ephemeral.service -p UnitFileState | grep "=disabled"') do
    its(:exit_status) { should eq 0 }
  end
end
