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
return if on_docker?

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

    def check_for_protected_mode(fleet_status_command)
      begin
        cluster_state_json = shell_out!("/bin/bash -c #{fleet_status_command}").stdout.strip
        cluster_state = JSON.load(cluster_state_json)
      rescue
        Chef::Log.warn("Unable to get compute fleet status")
        return
      end

      Chef::Log.info("Compute fleet status is empty") if cluster_state.empty?
      return if cluster_state.empty?

      raise "Cluster has been set to PROTECTED mode due to failures detected in static node provisioning" if cluster_state["status"] == "PROTECTED"
    end

    fleet_status_command = Shellwords.escape(
      "/usr/local/bin/get-compute-fleet-status.sh"
    )
    # Example output for sinfo
    # $ /opt/slurm/bin/sinfo -N -h -o '%N %t'
    # ondemand-dy-c52xlarge-1 idle~
    # ondemand-dy-c52xlarge-2 idle~
    # spot-dy-c5xlarge-1 idle~
    # spot-st-t2large-1 down
    # spot-st-t2large-2 idle
    # capacity-block-st-t2micro-1 maint
    # capacity-block-dy-t2micro-1 maint
    is_fleet_ready_command = Shellwords.escape(
      "set -o pipefail && #{node['cluster']['slurm']['install_dir']}/bin/sinfo -N -h -o '%N %t' | { grep -E '^[a-z0-9\\-]+\\-st\\-[a-z0-9\\-]+\\-[0-9]+ .*' || true; } | { grep -v -E '(idle|alloc|mix|maint)$' || true; }"
    )
    until shell_out!("/bin/bash -c #{is_fleet_ready_command}").stdout.strip.empty?
      check_for_protected_mode(fleet_status_command)

      Chef::Log.info("Waiting for static fleet capacity provisioning")
      sleep(15)
    end
    Chef::Log.info("Static fleet capacity is ready")
  end
end
