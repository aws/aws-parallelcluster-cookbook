# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-slurm
# Recipe:: finalize_head_node
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

execute "check if clustermgtd heartbeat is available" do
  command "cat #{node['cluster']['slurm']['install_dir']}/etc/pcluster/.slurm_plugin/clustermgtd_heartbeat"
  retries 30
  retry_delay 10
end

ruby_block "wait for static fleet capacity" do
  block do
    require 'chef/mixin/shell_out'
    require 'shellwords'
    require 'json'

    start_time = Time.now

    failure_count_cap = node['cluster']['failure_count_cap']
    failure_count_wait_time = node['cluster']['min_failure_count_time']

    check_for_failures = lambda do
      time_elapsed = Time.now - start_time

      Chef::Log.info("Not checking failure map yet. Time elapsed: #{time_elapsed}") if time_elapsed < failure_count_wait_time
      return if time_elapsed < failure_count_wait_time

      begin
        failure_map = JSON.load_file(node['cluster']['failure_count_map_path'])
      rescue
        Chef::Log.warn("Unable to load failure map")
        return
      end

      Chef::Log.info("failure_map is empty") if failure_map.empty?
      return if failure_map.empty?

      # Example contents of failure_map:
      #   {"queue-a": {"compute-a-1": 1, "compute-a-2": 2}, "queue-b": {"compute-b-1": 1}}
      max_failure_count = failure_map.map { |queue, compute_resources|
        compute_resources.map { |compute, count|
          {
            :queue => queue,
            :compute => compute,
            :count => count
          }
        }
      }.flatten(1).max_by { |item| item[:count] }

      Chef::Log.info("Maximum Failure: #{max_failure_count}")

      raise "Failed too many times waiting for static compute fleet to start. Queue: #{max_failure_count[:queue]}, Resource: #{max_failure_count[:compute]}, Failure Count: #{max_failure_count[:count]}" if failure_count_cap and max_failure_count[:count] >= failure_count_cap
    end

    # Example output for sinfo
    # $ /opt/slurm/bin/sinfo -N -h -o '%N %t'
    # ondemand-dy-c5.2xlarge-1 idle~
    # ondemand-dy-c5.2xlarge-2 idle~
    # spot-dy-c5.xlarge-1 idle~
    # spot-st-t2.large-1 down
    # spot-st-t2.large-2 idle
    is_fleet_ready_command = Shellwords.escape(
      "set -o pipefail && #{node['cluster']['slurm']['install_dir']}/bin/sinfo -N -h -o '%N %t' | { grep -E '^[a-z0-9\\-]+\\-st\\-[a-z0-9\\-]+\\-[0-9]+ .*' || true; } | { grep -v -E '(idle|alloc|mix)$' || true; }"
    )
    until shell_out!("/bin/bash -c #{is_fleet_ready_command}").stdout.strip.empty?
      check_for_failures.()

      Chef::Log.info("Waiting for static fleet capacity provisioning")
      sleep(15)
    end
    Chef::Log.info("Static fleet capacity is ready")
  end
end
