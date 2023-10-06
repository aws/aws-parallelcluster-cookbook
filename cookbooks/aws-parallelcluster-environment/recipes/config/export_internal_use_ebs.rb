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

case node['cluster']['node_type']
when 'HeadNode'
  # Export /opt/parallelcluster/shared
  volume "export #{node['cluster']['shared_dir']}" do
    shared_dir node['cluster']['shared_dir']
    action :export
  end

  # Export /opt/parallelcluster/shared_login_nodes
  volume "export #{node['cluster']['shared_dir_login_nodes']}" do
    shared_dir node['cluster']['shared_dir_login_nodes']
    action :export
  end

  # Export /opt/intel only if exists
  volume "export /opt/intel" do
    shared_dir "/opt/intel"
    only_if { ::File.directory?("/opt/intel") }
    action :export
  end

when 'ComputeFleet', 'LoginNode'
  Chef::Log.info("Export only from the HeadNode")
else
  raise "node_type must be HeadNode or ComputeFleet"
end
