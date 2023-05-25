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

# Job Info Management Demon
return unless node['cluster']['node_type'] == 'HeadNode' && node['cluster']['cluster_job_info_enabled']

# create log file for clusterjobinfomgtd
file "/var/log/parallelcluster/clusterjobinfomgtd" do
  owner 'root'
  group 'root'
  mode '0640'
end

template "/etc/parallelcluster/parallelcluster_jobinfomgtd.conf" do
  source 'jobinfomgtd/parallelcluster_jobinfomgtd.conf.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables(
    cluster_name: node['cluster']['stack_name'],
    instance_id: on_docker? ? 'instance_id' : node['ec2']['instance_id']
  )
end
