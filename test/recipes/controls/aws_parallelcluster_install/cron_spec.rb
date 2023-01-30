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

control 'cron_disabled_selected_daily_and_weekly_jobs' do
  title 'Test that selected required daily and weekly cron jobs are disabled'

  cron_job_deny_daily = %w(mlocate man-db.cron man-db).join("\n") << "\n"
  describe file('/etc/cron.daily/jobs.deny') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should eq cron_job_deny_daily }
  end

  cron_job_deny_weekly = %w(man-db).join("\n") << "\n"
  describe file('/etc/cron.weekly/jobs.deny') do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('owner') { should eq 'root' }
    its('group') { should eq 'root' }
    its('content') { should eq cron_job_deny_weekly }
  end
end
