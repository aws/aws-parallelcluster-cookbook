# frozen_string_literal: true

# Copyright:: 2026 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Download the bundle of Python wheels installed in a ParallelCluster virtualenv.
resource_name :pypi_dependencies
provides :pypi_dependencies
unified_mode true

property :dependency_type, String, name_property: true,
         description: 'Virtualenv the bundle is for: cookbook, node or cfn'
property :destination, String, required: true,
         description: 'Local path where to store the bundle'

default_action :download

action :download do
  package_file = "#{node['kernel']['machine']}/#{pypi_dependencies_package_name(new_resource.dependency_type)}.tgz"
  base_url = node['cluster']['pypi_dependencies_base_url']

  if base_url.start_with?('s3://')
    # Development builds stage the bundles in a private bucket, readable by the build instance role.
    execute "download #{new_resource.dependency_type} dependencies from #{base_url}" do
      command "#{AWS_CLI_BIN} s3 cp --region #{node['cluster']['region']} #{base_url}/#{package_file} #{new_resource.destination}"
      retries 3
      retry_delay 5
      creates new_resource.destination
    end
  else
    # No fallback to other bundles: a failed download must fail the build rather than install other dependencies.
    remote_file new_resource.destination do
      source "#{base_url}/#{package_file}"
      mode '0644'
      retries 3
      retry_delay 5
      action :create_if_missing
    end
  end
end
