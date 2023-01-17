# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-config
# Recipe:: aws_cli
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

# This recipe is expected to be executed only in isolated regions.
region = node['cluster']['region']
return unless region.start_with?('us-iso')

# Install CA bundle for US ISO
ca_bundle = "/etc/pki/#{region}/certs/ca-bundle.pem"
remote_file ca_bundle do
  source "#{node['cluster']['artifacts_s3_url']}/certificates/ca-bundle.pem"
  mode '0644'
  retries 3
  retry_delay 5
  not_if { ::File.exist?(ca_bundle) }
end

# Configure AWS CLI for US ISO region
include_recipe "aws-parallelcluster-config::aws_cli"
