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

# Mount the ephemeral drive unless there is a mountpoint collision with shared drives
shared_dir_array = node['cluster']['ebs_shared_dirs'].split(',') + \
                   node['cluster']['efs_shared_dirs'].split(',') + \
                   node['cluster']['fsx_shared_dirs'].split(',') + \
                   [ node['cluster']['raid_shared_dir'] ]

unless shared_dir_array.include? node['cluster']['ephemeral_dir']
  service "setup-ephemeral" do
    supports restart: false
    action :enable
  end unless on_docker?

  # Execution timeout 3600 seconds
  execute "Setup of ephemeral drives" do
    user "root"
    command "/usr/local/sbin/setup-ephemeral-drives.sh"
  end unless on_docker?
end
