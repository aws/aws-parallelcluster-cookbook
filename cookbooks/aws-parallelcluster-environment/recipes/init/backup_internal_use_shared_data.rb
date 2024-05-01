# frozen_string_literal: true

#
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

return if on_docker?

if node['cluster']['node_type'] == 'HeadNode'
  # For each, backup the data to a temp location
  # This is necessary to preserve any data in these directories that was
  # generated during the build of ParallelCluster AMIs after converting to
  # shared storage
  Chef::Log.info("Backup internal dirs #{node['cluster']['internal_shared_dirs']}")
  node['cluster']['internal_shared_dirs'].each do |dir|
    bash "Backup #{dir}" do
      user 'root'
      group 'root'
      code <<-EOH
        mkdir -p /tmp#{dir}
        rsync -a #{dir}/ /tmp#{dir}
      EOH
    end
  end
end
