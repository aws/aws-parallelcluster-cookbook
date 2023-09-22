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
  volume "export /home" do
    shared_dir "/home"
    action :export
  end
when 'ComputeFleet', 'LoginNode'
  Chef::Log.info("Export only from the HeadNode")
else
  raise "node_type must be HeadNode, ComputeFleet, or LoginNode"
end
