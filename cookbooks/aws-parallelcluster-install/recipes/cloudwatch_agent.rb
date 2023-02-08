# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: cloudwatch_agent
#
# Copyright:: 2013-2021 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

# Download the cloudwatch agent's public key. Note that the domain used to get
# the public key must NOT be regionalized.

# TODO: find a way to make this code work on ubi8
return if redhat_ubi?

remote_file node['cluster']['cloudwatch']['public_key_local_path'] do
  source node['cluster']['cloudwatch']['public_key_url']
  retries 3
  retry_delay 5
  not_if { ::File.exist?(node['cluster']['cloudwatch']['public_key_local_path']) }
end

# Set the s3 domain name to use for all download URLs
s3_domain = "https://s3.#{node['cluster']['region']}.#{node['cluster']['aws_domain']}"

# Set URLs used to download the package and expected signature based on platform
package_url_prefix = "#{s3_domain}/amazoncloudwatch-agent-#{node['cluster']['region']}"
arch_url_component = arm_instance? ? 'arm64' : 'amd64'
platform_url_component = value_for_platform(
  # No CW Agent for CentOS ARM, using RHEL package
  'centos' => { 'default' => arm_instance? ? 'redhat' : node['platform'] },
  'amazon' => { 'default' => 'amazon_linux' },
  'default' => node['platform']
)
Chef::Log.info("Platform for cloudwatch is #{platform_url_component}")
package_extension = platform?('ubuntu') ? 'deb' : 'rpm'
package_url = [
  package_url_prefix,
  platform_url_component,
  arch_url_component,
  "latest",
  "amazon-cloudwatch-agent.#{package_extension}",
].join('/')
package_path = "#{node['cluster']['sources_dir']}/amazon-cloudwatch-agent.#{package_extension}"
signature_url = "#{package_url}.sig"
signature_path = "#{package_path}.sig"

# Download package and its expected signature
remote_file signature_path do
  source signature_url
  retries 3
  retry_delay 5
  not_if { ::File.exist?(signature_path) }
end
remote_file package_path do
  source package_url
  retries 3
  retry_delay 5
  not_if { ::File.exist?(package_path) }
end

# Import cloudwatch agent's public key to the keyring
execute "import-cloudwatch-agent-key" do
  command "gpg --import #{node['cluster']['cloudwatch']['public_key_local_path']}"
  user 'root'
end

# Verify that cloudwatch agent's public key has expected fingerprint
cookbook_file 'verify_cloudwatch_agent_public_key_fingerprint.py' do
  not_if { ::File.exist?('/usr/local/bin/verify_cloudwatch_agent_public_key_fingerprint.py') }
  source 'cloudwatch_agent/verify_cloudwatch_agent_public_key_fingerprint.py'
  path '/usr/local/bin/verify_cloudwatch_agent_public_key_fingerprint.py'
  user 'root'
  group 'root'
  mode '0755'
end
execute "verify-cloudwatch-agent-public-key-fingerprint" do
  command "#{node.default['cluster']['cookbook_virtualenv_path']}/bin/python /usr/local/bin/verify_cloudwatch_agent_public_key_fingerprint.py"
  user 'root'
end

# Verify that the cloudwatch agent package matches its expected signature
execute "verify-cloudwatch-agent-rpm-signature" do
  command "gpg --verify #{signature_path} #{package_path}"
end

# Install package.
case node['platform']
when 'ubuntu'
  # Use dpkg for ubuntu because apt provider doesn't work for local installs
  dpkg_package package_path do
    source package_path
  end
when 'amazon', 'centos', 'redhat'
  package package_path
end
