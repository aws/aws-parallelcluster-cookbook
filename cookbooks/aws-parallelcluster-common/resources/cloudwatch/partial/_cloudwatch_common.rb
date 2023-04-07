# frozen_string_literal: true

#
# Copyright:: 2023 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file.
# This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or implied.
# See the License for the specific language governing permissions and limitations under the License.

unified_mode true
default_action :setup

action :setup do
  remote_file node['cluster']['cloudwatch']['public_key_local_path'] do
    source node['cluster']['cloudwatch']['public_key_url']
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # Set the s3 domain name to use for all download URLs
  s3_domain = "https://s3.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}"

  # Set URLs used to download the package and expected signature based on platform
  package_url_prefix = "#{s3_domain}/amazoncloudwatch-agent-#{node['cluster']['region']}"
  arch_url_component = arm_instance? ? 'arm64' : 'amd64'
  Chef::Log.info("Platform for cloudwatch is #{platform_url_component}")
  package_url = [
    package_url_prefix,
    platform_url_component,
    arch_url_component,
    'latest',
    "amazon-cloudwatch-agent.#{package_extension}",
  ].join('/')
  signature_url = "#{package_url}.sig"
  signature_path = "#{package_path}.sig"

  # Download package and its expected signature
  remote_file signature_path do
    source signature_url
    retries 3
    retry_delay 5
    action :create_if_missing
  end
  remote_file package_path do
    source package_url
    retries 3
    retry_delay 5
    action :create_if_missing
  end

  # Import cloudwatch agent's public key to the keyring
  execute 'import-cloudwatch-agent-key' do
    command "gpg --import #{node['cluster']['cloudwatch']['public_key_local_path']}"
  end

  # Verify that cloudwatch agent's public key has expected fingerprint
  execute 'verify-cloudwatch-agent-public-key-fingerprint' do
    command 'gpg --list-keys --fingerprint "Amazon CloudWatch Agent" | grep "9376 16F3 450B 7D80 6CBD  9725 D581 6730 3B78 9C72"'
  end

  # Verify that the cloudwatch agent package matches its expected signature
  execute 'verify-cloudwatch-agent-rpm-signature' do
    command "gpg --verify #{signature_path} #{package_path}"
  end

  action_cloudwatch_install_package
end

action_class do
  def package_path
    "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.#{package_extension}"
  end
end
