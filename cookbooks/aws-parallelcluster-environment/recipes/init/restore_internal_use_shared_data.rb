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
  # For each, restore the shared storage if it doesn't already exist
  # This is necessary to preserve any data in these directories that was
  # generated during the build of ParallelCluster AMIs after converting to
  # shared storage and backed up to a temporary location previously
  # Remove the backup after the copy is done
  node['cluster']['internal_shared_dirs'].each do |dir|
    bash "Restore #{dir}" do
      user 'root'
      group 'root'
      code <<-EOH
        rsync -a --ignore-existing /tmp#{dir}/ #{dir}
        rm -rf /tmp#{dir}/
      EOH
    end
  end
end
