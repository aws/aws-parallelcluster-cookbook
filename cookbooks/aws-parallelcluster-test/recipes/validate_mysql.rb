# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: validate_mysql
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

#
# Check the repository source of a package
#
unless platform?('ubuntu')
  Chef::Log.info("Checking for MySql implementation on #{node['platform']}:#{node['kernel']['machine']}")
  node['cluster']['mysql']['repository']['packages'].each do |pkg|
    validate_package_version(pkg, node['cluster']['mysql']['repository']['expected']['version'])
  end
end
