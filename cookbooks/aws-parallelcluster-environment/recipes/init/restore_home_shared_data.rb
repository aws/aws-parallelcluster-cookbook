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
  # Restore the shared storage home data if it doesn't already exist
  # This is necessary to preserve any data in these directories that was
  # generated during the build of ParallelCluster AMIs after converting to
  # shared storage and backed up to a temporary location previously
  # Before removing the backup, ensure the data in the new home is the same
  # as the original to avoid any data loss or inconsistency. This is done
  # by using rsync to copy the data and diff to check for differences.
  # Remove the backup after the copy is done and the data integrity is verified.
  bash "Restore /home" do
    user 'root'
    group 'root'
    code <<-EOH
      rsync -a --ignore-existing /tmp/home/ /home
      diff -r /tmp/home/ /home
      if [ $? -eq 0 ]; then
        rm -rf /tmp/home/
      else
        echo "Data integrity check failed for /home"
        exit 1
      fi
    EOH
  end
end
