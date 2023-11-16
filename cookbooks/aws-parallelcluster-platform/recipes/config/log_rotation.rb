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

case node['cluster']['node_type']

when 'HeadNode'
  include_recipe 'aws-parallelcluster-platform::log_rotation_head_node'

when 'ComputeFleet'
  include_recipe 'aws-parallelcluster-platform::log_rotation_compute_fleet'

when 'LoginNode'
  include_recipe 'aws-parallelcluster-platform::log_rotation_login_node'

else
  raise "node_type must be HeadNode, LoginNode or ComputeFleet"

end
