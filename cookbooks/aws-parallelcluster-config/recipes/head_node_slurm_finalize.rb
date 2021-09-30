# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: head_node_slurm_finalize
#
# Copyright 2013-2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
  command "cat /opt/slurm/etc/pcluster/.slurm_plugin/clustermgtd_heartbeat"
  retries 30
  retry_delay 10
end

ruby_block "wait for static fleet capacity" do # ~FC014
  block do
    require 'chef/mixin/shell_out'
    require 'shellwords'

    # Example output for sinfo
    # $ /opt/slurm/bin/sinfo -N -h -o '%N %t'
    # ondemand-dy-c5.2xlarge-1 idle~
    # ondemand-dy-c5.2xlarge-2 idle~
    # spot-dy-c5.xlarge-1 idle~
    # spot-st-t2.large-1 down
    # spot-st-t2.large-2 idle
    is_fleet_ready_command = Shellwords.escape(
      "set -o pipefail && /opt/slurm/bin/sinfo -N -h -o '%N %t' | { grep -E '^[a-z0-9\\-]+\\-st\\-[a-z0-9]+\\-[0-9]+ .*' || true; } | { grep -v -E '(idle|alloc|mix)$' || true; }"
    )
    until shell_out!("/bin/bash -c #{is_fleet_ready_command}").stdout.strip.empty?
      Chef::Log.info("Waiting for static fleet capacity provisioning")
      sleep(15)
    end
    Chef::Log.info("Static fleet capacity is ready")
  end
end

ruby_block "wait for dynamic fleet capacity" do
  block do
    require 'chef/mixin/shell_out'
    require 'shellwords'

    # $ /opt/slurm/bin/squeue --name='parallelcluster-init-cluster' -O state -h
    # CONFIGURING
    # RUNNING
    are_jobs_running_command = Shellwords.escape("set -o pipefail && /opt/slurm/bin/squeue --name='parallelcluster-init-cluster' -O state -h | { grep -v 'RUNNING' || true; }")
    until shell_out!("/bin/bash -c #{are_jobs_running_command}").stdout.strip.empty?
      Chef::Log.info("Waiting for dynamic fleet capacity provisioning")
      sleep(15)
    end
    Chef::Log.info("Dynamic fleet capacity is ready. Terminating provisioning jobs.")
    shell_out!("/opt/slurm/bin/scancel --jobname=parallelcluster-init-cluster")
  end
end
