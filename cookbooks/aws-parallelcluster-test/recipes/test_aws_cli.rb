# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster-test
# Recipe:: test_aws_cli
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

region = node["cluster"]["region"]

# Users to verify the AWS CLI configuration for.
# We verify all the users that are created by ParallelCluster and must interact with AWS.
users = [
  "root",
  node["cluster"]["cluster_user"],
  node["cluster"]["cluster_admin_user"],
  node["cluster"]["slurm"]["user"],
]
users.append(node["cluster"]["scheduler_plugin"]["user"]) if node["cluster"]["scheduler"] == "plugin"

# AWS CLI configurations to verify.
# Note: a configuration with an empty value is equivalent to a not set configuration.
configurations = {
  "ca_bundle" =>  region.start_with?("us-iso") ? "/etc/pki/#{region}/certs/ca-bundle.pem" : "",
}

def check_aws_cli_configuration(config_name, expected_value, user)
  bash "Check AWS CLI configuration for user #{user}: #{config_name} should be '#{expected_value}'" do
    cwd Chef::Config[:file_cache_path]
    user user
    login true
    code <<-TEST
      actual_value=$(aws configure get #{config_name})
      if [ "$actual_value" != "#{expected_value}" ]; then
        >&2 echo "ERROR The AWS CLI configuration is not as expected for user #{user}: #{config_name} should be '#{expected_value}', but it is '$actual_value'."
        exit 1
      fi
    TEST
  end
end

users.each do |user|
  configurations.each do |config_name, config_value|
    check_aws_cli_configuration(config_name, config_value, user)
  end
end
