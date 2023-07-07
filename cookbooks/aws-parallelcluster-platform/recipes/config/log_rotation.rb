# frozen_string_literal: true

#
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

return if node['cluster']['log_rotation_enabled'] != 'true'

# TODO: move the logrotate configuration of the various services to the corresponding recipes/cookbooks.

# Here are general logrotate configuration present in all types of nodes
logrotate_conf_dir = node['cluster']['logrotate_conf_dir']

template logrotate_conf_dir + 'parallelcluster_cloud_init_log_rotation' do
  source 'log_rotation/parallelcluster_cloud_init_log_rotation.erb'
  mode '0644'
end

template logrotate_conf_dir + 'parallelcluster_supervisord_log_rotation' do
  source 'log_rotation/parallelcluster_supervisord_log_rotation.erb'
  mode '0644'
end

template logrotate_conf_dir + 'parallelcluster_bootstrap_error_msg_log_rotation' do
  source 'log_rotation/parallelcluster_bootstrap_error_msg_log_rotation.erb'
  mode '0644'
end

# Here are logrotate configuration specific only to some types of nodes
case node['cluster']['node_type']

when 'HeadNode'
  include_recipe 'aws-parallelcluster-platform::log_rotation_head_node'

when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-platform::log_rotation_compute_fleet'

else
  raise "node_type must be HeadNode or ComputeFleet"

end
