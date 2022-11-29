# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
#
# Copyright:: 2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

module WriteChefError
  # this class is used to handle chef errors and write the errors into a certain file if the file does not exist yet
  class WriteChefError < Chef::Handler
    def report
      extend Chef::Mixin::ShellOut
      # the run_status object is initialized by Chef Infra Client and keep track of status of a Chef Infra Client run
      # the "failed?" property is evaluated to be true when a Chef Infra Client run fails
      # reference: https://docs.chef.io/handlers/#run_status-object
      if run_status.failed?
        error_file = node['cluster']['bootstrap_error_path']
        unless File.exist?(error_file)
          more_details = if node['cluster']['node_type'] == 'HeadNode'
                           "/var/log/chef-client.log and /var/log/cloud-init-output.log"
                         else
                           "/var/log/cloud-init-output.log"
                         end
          message = "Failed when running chef recipes (If --rollback-on-failure was set to false, more details can be found in '#{more_details}'.):"
          shell_out("echo '#{message}' '#{run_status.formatted_exception}' > '#{error_file}'")
        end
      end
    end
  end
end
