# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: test_dcv
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

return unless node['cluster']['node_type'] == "HeadNode" && node['conditions']['dcv_supported'] && graphic_instance? && nvidia_installed? && dcv_gpu_accel_supported?

bash "check nice-dcv-gl installation" do
  cwd Chef::Config[:file_cache_path]
  code <<-TEST
    package_name="nice-dcv-gl"
    expected_package_version="#{node['cluster']['dcv']['gl']['version']}"

    echo "Testing nice-dcv-gl installation"
    if [[ "#{node['platform_family']}" == "rhel" || "#{node['platform_family']}" == "amazon" ]]; then
      yum list installed | grep ${package_name} | grep ${expected_package_version} || exit 1
    else
      apt list --installed | grep ${package_name} | grep ${expected_package_version} || exit 1
    fi
    echo "nice-dcv-gl test passed: the package is installed with the expected version ${expected_package_version}"
  TEST
end
