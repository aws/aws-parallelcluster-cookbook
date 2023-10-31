# frozen_string_literal: true

# Copyright:: 2013-2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.
# rubocop:disable Style/SingleArgumentDig

require 'digest'

cluster_name = node['cluster']['cluster_name'] || node['cluster']['stack_name']
pool_name = lazy { node['cluster']['config'].dig(:LoginNodes, :Pools, 0, :Name) }

# 定义函数，模拟 Python 的 get_target_group_name 函数
def get_target_group_name(cluster_name, pool_name)
  partial_cluster_name = cluster_name[0..6]
  partial_pool_name = pool_name[0..6]
  combined_name = cluster_name + pool_name
  hash_value = Digest::SHA256.hexdigest(combined_name)[0..15]
  "#{partial_cluster_name}-#{partial_pool_name}-#{hash_value}"
end

target_group_name = get_target_group_name(cluster_name, pool_name)

template "#{node['cluster']['scripts_dir']}/slurm/check_login_nodes_stopped.sh" do
  source 'slurm/head_node/check_login_nodes_stopped.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    target_group_name: target_group_name,
    region: node['cluster']['region']
  )
  only_if do
    node['cluster']['config'].dig(:LoginNodes)
  end
end
