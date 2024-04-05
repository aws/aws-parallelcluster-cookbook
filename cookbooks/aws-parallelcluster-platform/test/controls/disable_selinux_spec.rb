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

control 'tag:install_selinux_disabled' do
  title 'Check if selinux is disabled'
  describe selinux do
    it { should be_disabled }
    it { should_not be_enforcing }
  end unless os_properties.alinux2023? || os_properties.redhat? || os_properties.rocky? || os_properties.centos? # Because it requires reboot of the instance
end

control 'tag:testami_selinux_disabled' do
  title 'Check if selinux is disabled'
  describe selinux do
    it { should be_disabled }
    it { should_not be_enforcing }
  end
end
