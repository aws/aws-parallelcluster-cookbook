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

control 'cloudwatch_agent_configured' do
  title 'Check that cloudwatch agent is correctly configured'

  only_if { !os_properties.redhat_ubi? }

  describe file('/usr/local/bin/write_cloudwatch_agent_json.py') do
    it { should exist }
    its('mode') { should cmp '0755' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should_not be_empty }
  end

  files = %w(/usr/local/etc/cloudwatch_agent_config.json /usr/local/etc/cloudwatch_agent_config_schema.json /usr/local/bin/cloudwatch_agent_config_util.py)
  files.each do |file|
    describe file(file) do
      it { should exist }
      its('mode') { should cmp '0644' }
      its('owner') { should eq 'root' }
      its('group') { should eq 'root' }
    end
  end

  desc 'Cloudwatch Agent config should have been created'
  describe file('/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json') do
    it { should exist }
    its('content') { should_not be_empty }
  end

  desc 'CloudWatch Agent should be running'
  describe bash('/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status | grep status | grep running') do
    its('exit_status') { should eq(0) }
  end
end
