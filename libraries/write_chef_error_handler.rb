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
      error_file = node['cluster']['bootstrap_error_path']

      # to avoid overwriting the error message from other mechanisms, such as the deprecated BYOS handler
      # if the error file already exists we don't take any additional action here
      unless File.exist?(error_file)
        message_error = 'Failed to run chef recipe.'
        message_logs_to_check =
          if node['cluster']['node_type'] == 'HeadNode'
            'Please check /var/log/chef-client.log in the head node, or check the chef-client.log in CloudWatch logs.'
          else
            'Please check the cloud-init-output.log in CloudWatch logs.'
          end
        message_troubleshooting_link = 'Please refer to'\
          ' https://docs.aws.amazon.com/parallelcluster/latest/ug/troubleshooting-v3.html#troubleshooting-v3-get-logs'\
          ' for more details on ParallelCluster logs.'

        # get the failed action records using the chef function filtered_collection
        # reference: https://github.com/cinc-project/chef/blob/stable/cinc/lib/chef/action_collection.rb#L107
        failed_action_collection = action_collection.filtered_collection(
          up_to_date: false, skipped: false, updated: false, failed: true, unprocessed: false
        )

        # define a mapping from the mount-related resource name to the error message we would like to display
        mount_message_mapping = {
          "add ebs" => "Failed to mount EBS volume.",
          "add raid" => "Failed to mount RAID array.",
          "mount efs" => "Failed to mount EFS.",
          "mount fsx" => "Failed to mount FSX.",
        }

        failed_action_collection.each do |action_record|
          # there might be multiple failed action records
          # here we only look at the outermost layer resource by setting nesting_level = 0
          # with the assumption that there is only one failed action record with nesting_level = 0
          next unless action_record.nesting_level == 0
          # we first check if it is a storage mounting error
          if action_record.action == :mount
            if mount_message_mapping.key?(action_record.new_resource.name)
              message_error = mount_message_mapping[action_record.new_resource.name]
            end
          end
          # if we didn't detect any storage mounting error for EBS, RAID, EFS, or FSX,
          # then we will get the recipe information
          if message_error == 'Failed to run chef recipe.'
            recipe_info = get_recipe_info(action_record)
            message_error = "Failed to run chef recipe#{recipe_info}."
          end
          break
        end

        # at the end, put together and store the full error message into the dedicated file
        shell_out("echo '#{message_error} #{message_logs_to_check} #{message_troubleshooting_link}'> '#{error_file}'")

      end
    end

    def get_recipe_info(action_record)
      # reference: https://github.com/cinc-project/chef/blob/stable/cinc/lib/chef/resource.rb#L1436
      cookbook_name = action_record.new_resource.cookbook_name
      recipe_name = action_record.new_resource.recipe_name
      source_line = action_record.new_resource.source_line
      if source_line
        source_line_matches = source_line.match(/(.*):(\d+):?.*$/).to_a
        source_line_file = source_line_matches[1]
        source_line_number = source_line_matches[2]
        recipe_info =
          if cookbook_name && recipe_name
            " #{cookbook_name}::#{recipe_name} line #{source_line_number}"
          else
            " #{source_line_file} line #{source_line_number}"
          end
      else
        recipe_info = ""
      end
      recipe_info
    end
  end
end
