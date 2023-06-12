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

# generate the parallelcluster log rotation under /etc/logrotate.d
template node['cluster']['pcluster_log_rotation_path'] do
  source 'log_rotation/parallelcluster_log_rotation.erb'
  mode '0644'
  only_if { node['cluster']['log_rotation_enabled'] == 'true' }
  variables(dcv_configured: node['cluster']['dcv_enabled'] == "head_node" && dcv_installed?)
end
