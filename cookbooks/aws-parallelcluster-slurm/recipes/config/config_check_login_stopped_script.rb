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

template "#{node['cluster']['scripts_dir']}/slurm/check_login_nodes_stopped.sh" do
  source 'slurm/head_node/check_login_nodes_stopped.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables(
    target_group_names: lazy do
      # Generate a string that is the array representation in bash (e.g. "(item1, item2, item3)")
      "(#{node['cluster']['config'].dig(:LoginNodes, :Pools).map do |pool_config|
        get_target_group_name(
          node['cluster']['cluster_name'] || node['cluster']['stack_name'],
          pool_config['Name']
        )
      end.join(' ')})"
    end,
    region: node['cluster']['region']
  )
  only_if do
    node['cluster']['config'].dig(:LoginNodes)
  end
end
