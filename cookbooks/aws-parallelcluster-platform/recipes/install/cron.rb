# frozen_string_literal: true
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
#

# Create directories if not existing
directory '/etc/cron.daily'
directory '/etc/cron.weekly'

# Disable cron/anacron jobs that may impact performance
cookbook_file 'cron.jobs.deny.daily' do
  source 'cron/jobs.deny.daily'
  path '/etc/cron.daily/jobs.deny'
  owner 'root'
  group 'root'
  mode '0644'
end

cookbook_file 'cron.jobs.deny.weekly' do
  source 'cron/jobs.deny.weekly'
  path '/etc/cron.weekly/jobs.deny'
  owner 'root'
  group 'root'
  mode '0644'
end
