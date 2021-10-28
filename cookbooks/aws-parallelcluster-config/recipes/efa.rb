# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: efa
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

if platform?('ubuntu') && node['cluster']['enable_efa'] == 'compute' && node['cluster']['node_type'] == 'ComputeFleet'
  # Disabling ptrace protection is needed for EFA in order to use SHA transfer for intra-node communication.
  sysctl 'kernel.yama.ptrace_scope' do
    value 0
  end
end
