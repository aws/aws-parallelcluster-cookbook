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

control 'hostname_configured' do
  title 'Checks hostname is properly set'

  describe file('/etc/hostname') do
    it { should exist }
    its('content') do
      should match("^ip-[0-9]*-[0-9]*-[0-9]*-[0-9]*")
    end
  end

  describe file('/etc/hosts') do
    it { should exist }
    its('content') do
      should match("^[0-9]*.[0-9]*.[0-9]*.[0-9]*")
      should match("ip-[0-9]*-[0-9]*-[0-9]*-[0-9]*")
    end
  end
end
