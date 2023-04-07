# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: emit_chef_error_event
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
  # this class is used to handle chef errors and write the errors into a certain file for slurm scheduler
  class WriteComputeFleetSlurmChefError < Chef::Handler
    def report
      require 'date'
      error_file = node["cluster"]["bootstrap_error_path"]

      # get the failed action records using the chef function filtered_collection
      # reference: https://github.com/cinc-project/chef/blob/stable/cinc/lib/chef/action_collection.rb#L107
      failed_action_collection = action_collection.filtered_collection(
        up_to_date: false, skipped: false, updated: false, failed: true, unprocessed: false
      )
      failures = failed_action_collection.map { |action_record| get_failure_detail(action_record) }.compact
      error_info = get_error_info(node, failures)
      IO.write(error_file, error_info.to_json + "\n")

      # the 5s sleep time here will extend the overall sleep time set in the CLI repo:
      # cli/src/pcluster/resources/compute_node/user_data.sh, in order to allow CW agent enough time
      # to detect this new error log file, create the logstream and push the content to the logstream
      sleep(5)
    end

    def get_failure_detail(action_record)
      {
        "exception-type" => action_record.exception.class.name,
        "error-title" => action_record.error_description["title"],
        "nesting-level" => action_record.nesting_level,
        "cookbook-name" => action_record.new_resource.cookbook_name,
        "recipe-name" => action_record.new_resource.recipe_name,
        "source-line" => action_record.new_resource.source_line,
        "resource-name" => action_record.new_resource.name,
        "resource-type" => action_record.new_resource.declared_type,
        "action" => action_record.action,
      }
    end

    def get_error_info(node, failures)
      {
        "datetime" => DateTime.now,
        "version" => 0,
        "cluster-name" => node["cluster"]["cluster_name"],
        "scheduler" => node["cluster"]["scheduler"],
        "node-role" => "ComputeFleet",
        "level" => "ERROR",
        "instance-id" => node["ec2"]["instance_id"],
        "event-type" => "chef-recipe-exception",
        "message" => "Chef recipe exception",
        "component" => get_component(node.override_runlist),
        "compute" => {
          "name" => node["cluster"]["slurm_nodename"],
          "instance-id" => node["ec2"]["instance_id"],
          "instance-type" => node["ec2"]["instance_type"],
          "availability-zone" => node["ec2"]["availability_zone"],
          "address" => node["ipaddress"],
          "hostname" => node["ec2"]["hostname"],
          "queue-name" => node["cluster"]["scheduler_queue_name"],
          "compute-resource" => node["cluster"]["scheduler_compute_resource_name"],
          "node-type" => get_node_type(node["cluster"]["slurm_nodename"]),
        },
        "detail" => {
          "failures" => failures,
        },
      }
    end

    def get_node_type(node_name)
      if node_name.nil?
        nil
      else
        is_static_node?(node_name) ? "static" : "dynamic"
      end
    end

    def get_component(runlist)
      # get the component from node.override_runlist
      # match the "aws-parallelcluster::init" format
      # return one of these values: "init", "configure", "finalize"
      match = runlist[0].name.match(/^([a-z\-]+)::([a-z]+)$/)
      raise "Failed when parsing the runlist: #{runlist}" if match.nil?
      match[2]
    end
  end
end
