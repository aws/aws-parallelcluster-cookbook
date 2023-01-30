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

control 'chrony_installed_and_configured' do
  title 'Test chrony installation and configuration'

  describe package('chrony') do
    it { should be_installed }
  end unless os_properties.redhat_ubi?

  describe package('ntp') do
    it { should_not be_installed }
  end

  describe package('ntpdate') do
    it { should_not be_installed }
  end

  if os.redhat?
    chrony_file = '/etc/chrony.conf'
  elsif os.debian?
    chrony_file = '/etc/chrony/chrony.conf'
  else
    describe "unsupported OS" do
      # this produces a skipped control (ignore-like)
      # adding a new OS to kitchen platform list and running the tests,
      # it would surface the fact this recipe does not support this OS.
      pending "support for #{os.name}-#{os.release} needs to be implemented"
    end
  end

  describe file(chrony_file) do
    it { should exist }
    its('content') { should match(/server 169.254.169.123 prefer iburst minpoll 4 maxpoll 4/) }
  end
end
