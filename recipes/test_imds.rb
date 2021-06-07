# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: test_imds
#
# Copyright 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

all_users = get_system_users
allowed_users =
  if node['cluster']['node_type'] == 'HeadNode' &&
     node['cluster']['scheduler'] == 'slurm' &&
     node['cluster']['head_node_imds_secured'] == 'true'
    node['cluster']['head_node_imds_allowed_users']
  else
    all_users
  end

denied_users = all_users - allowed_users

allowed_users.each { |allowed_user| check_imds_access(allowed_user, true) }

denied_users.each { |denied_user| check_imds_access(denied_user, false) }
