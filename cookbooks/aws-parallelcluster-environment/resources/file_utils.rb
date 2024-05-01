# frozen_string_literal: true

# Copyright:: 2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance
# with the License. A copy of the License is located at http://aws.amazon.com/apache2.0/
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

provides :file_utils
unified_mode true

property :file, String, required: %i(check_active_processes)

default_action :check_active_processes

action :check_active_processes do
  file = new_resource.file
  Chef::Log.info("The following processes are using #{file}")
  execute "active processes" do
    retries 3
    retry_delay 3
    timeout 10
    live_stream true
    command "fuser -mv #{file}"
  end
end
