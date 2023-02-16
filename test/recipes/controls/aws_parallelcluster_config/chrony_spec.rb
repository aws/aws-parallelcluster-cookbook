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

control 'chrony_configured' do
  title 'Check that chrony is correctly configured'

  only_if { !os_properties.virtualized? }

  chrony_service = os_properties.debian_family? ? 'chrony' : 'chronyd'

  describe service(chrony_service) do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end

  describe bash("systemctl show #{chrony_service} | grep 'Restart=no'") do
    its('exit_status') { should eq(0) }
  end
end
