# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-platform
# Recipe:: disable_services
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# If the service does not exist the action disable does not return error.
# Masking the service in order to prevent it from being automatically enabled if not installed yet.

# on alinux2023, enable ryslog
service 'rsyslog' do
  supports restart: true
  action %i(enable start)
  retries 5
  retry_delay 10
end unless on_docker?
