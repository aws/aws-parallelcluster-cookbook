# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: tests_mock
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

# Recipe used to mock node environment before the execution of kitchen tests

# mock launch templates config content
file node['cluster']['launch_templates_config_path'] do
  content <<-LAUNCH_TEMPLATE_DATA
{
  "Queues": {
    "queue1": {
      "ComputeResources": {
        "computeresource1": {
          "LaunchTemplate": {
            "Version": "1",
            "Id": "lt-1234567890abcd"
          }
        }
      }
    },
    "queue2": {
      "ComputeResources": {
        "computeresource1": {
          "LaunchTemplate": {
            "Version": "1",
            "Id": "lt-dcba0987654321"
          }
        }
      }
    }
  }
}
LAUNCH_TEMPLATE_DATA
  mode '0644'
  owner 'root'
  group 'root'
end
