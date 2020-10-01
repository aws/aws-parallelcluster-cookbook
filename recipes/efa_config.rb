# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: efa_config
#
# Copyright 2013-2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Installation recipe must be re-executed at runtime to enable GDR
include_recipe "aws-parallelcluster::efa_install"

if node['platform'] == 'ubuntu'
  if node['cfncluster']['enable_efa'] == 'compute' && node['cfncluster']['cfn_node_type'] == 'ComputeFleet'
    # Disabling ptrace protection is needed for EFA in order to use SHA transfer for intra-node communication.
    replace_or_add "disable ptrace protection" do
      path "/etc/sysctl.d/10-ptrace.conf"
      pattern "kernel.yama.ptrace_scope"
      line "kernel.yama.ptrace_scope = 0"
      notifies :run, 'execute[reload ptrace sysctl settings]', :immediately
    end

    execute "reload ptrace sysctl settings" do
      action :nothing
      command 'sysctl -p /etc/sysctl.d/10-ptrace.conf'
    end
  end
end
