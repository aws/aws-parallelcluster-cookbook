# frozen_string_literal: true

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

return unless node['cluster']['scheduler'] == 'awsbatch'

# Install aws-parallelcluster-awsbatch-cli.cfg
awsbatch_cli_dir = "/home/#{node['cluster']['cluster_user']}/.parallelcluster/"

directory awsbatch_cli_dir do
  owner node['cluster']['cluster_user']
  group node['cluster']['cluster_user']
  recursive true
end

template "#{awsbatch_cli_dir}/awsbatch-cli.cfg" do
  source 'awsbatch/awsbatch-cli.cfg.erb'
  owner node['cluster']['cluster_user']
  group node['cluster']['cluster_user']
  mode '0644'
end
