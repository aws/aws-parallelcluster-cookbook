# frozen_string_literal: true

#
# Cookbook Name:: aws-parallelcluster
# Recipe:: cloudwatch_agent_install
#
# Copyright 2013-2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
remote_file node['cfncluster']['cloudwatch']['public_key_local_path'] do
  source node['cfncluster']['cloudwatch']['public_key_url']
  retries 3
  retry_delay 5
  not_if { ::File.exist?(node['cfncluster']['cloudwatch']['public_key_local_path']) }
end

# Set the s3 domain name to use for all download URLs
s3_domain = "https://s3.#{node['cfncluster']['cfn_region']}.amazonaws.com"
s3_domain = "#{s3_domain}.cn" if node['cfncluster']['cfn_region'].start_with?("cn-")

# Set URLs used to download the package and expected signature based on platform
package_url_prefix = "#{s3_domain}/amazoncloudwatch-agent-#{node['cfncluster']['cfn_region']}"
case node['platform']
when 'ubuntu'
  package_url = "#{package_url_prefix}/#{node['platform']}/amd64/latest/amazon-cloudwatch-agent.deb"
  package_path = "#{node['cfncluster']['sources_dir']}/amazon-cloudwatch-agent.deb"
when 'amazon'
  # NOTE: the URL used to get amazon linux's package does not use node['platform']
  package_url = "#{package_url_prefix}/amazon_linux/amd64/latest/amazon-cloudwatch-agent.rpm"
  package_path = "#{node['cfncluster']['sources_dir']}/amazon-cloudwatch-agent.rpm"
when 'centos'
  package_url = "#{package_url_prefix}/#{node['platform']}/amd64/latest/amazon-cloudwatch-agent.rpm"
  package_path = "#{node['cfncluster']['sources_dir']}/amazon-cloudwatch-agent.rpm"
end
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
  command "gpg --import #{node['cfncluster']['cloudwatch']['public_key_local_path']}"
  user 'root'
end

# Verify that cloudwatch agent's public key has expected fingerprint
cookbook_file 'verify_cloudwatch_agent_public_key_fingerprint.py' do
  not_if { ::File.exist?('/usr/local/bin/verify_cloudwatch_agent_public_key_fingerprint.py') }
  path '/usr/local/bin/verify_cloudwatch_agent_public_key_fingerprint.py'
  user 'root'
  group 'root'
  mode '0755'
end
execute "verify-cloudwatch-agent-public-key-fingerprint" do
  command "#{node.default['cfncluster']['cookbook_virtualenv_path']}/bin/python /usr/local/bin/verify_cloudwatch_agent_public_key_fingerprint.py"
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
when 'amazon', 'centos'
  package package_path
end
