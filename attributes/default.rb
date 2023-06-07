# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Attributes:: default
#
# Copyright:: 2013-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# ParallelCluster log dir
default['cluster']['bootstrap_error_path'] = "#{node['cluster']['log_base_dir']}/bootstrap_error_msg"

# ParallelCluster log rotation file dir
default['cluster']['pcluster_log_rotation_path'] = "/etc/logrotate.d/parallelcluster_log_rotation"

# Cluster config
default['cluster']['cluster_s3_bucket'] = nil
default['cluster']['cluster_config_s3_key'] = nil
default['cluster']['cluster_config_version'] = nil
default['cluster']['change_set_s3_key'] = nil
default['cluster']['instance_types_data_s3_key'] = nil
default['cluster']['skip_install_recipes'] = 'yes'
# Official ami build
default['cluster']['is_official_ami_build'] = false

# ParallelCluster internal variables (also in /etc/parallelcluster/cfnconfig)
default['cluster']['stack_name'] = nil
default['cluster']['scheduler_queue_name'] = nil
default['cluster']['instance_slots'] = '1'
default['cluster']['proxy'] = 'NONE'
default['cluster']['volume'] = ''

# Compute nodes bootstrap timeout
default['cluster']['compute_node_bootstrap_timeout'] = 1800
