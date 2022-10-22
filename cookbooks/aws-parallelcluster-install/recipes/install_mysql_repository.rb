# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: install_mysql_repository
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

unless platform?('ubuntu') && arm_instance?
  install_repository_definition(
    "MySQL Repository",
    node['cluster']['mysql']['repository']['definition']['url'],
    "/tmp/#{node['cluster']['mysql']['repository']['definition']['file-name']}",
    node['cluster']['mysql']['repository']['definition']['md5']
  )
end
