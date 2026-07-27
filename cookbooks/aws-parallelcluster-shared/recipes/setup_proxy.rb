# frozen_string_literal: true

#
# Cookbook:: aws-parallelcluster
# Recipe:: setup_proxy
#
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

# This recipe configures proxy environment variables for build-image in isolated networks.
#
# It reads the proxy URL from node['cluster']['install_http_proxy_address'] (set via ExtraChefAttributes)
# and configures http_proxy/https_proxy ENV vars for the Chef run. This makes all subsequent
# Chef resources (remote_file, bash, execute, etc.) use the explicit proxy for HTTPS traffic
# instead of trying direct connections that would fail in an isolated network.
#
# The no_proxy list excludes S3 endpoints so downloads from S3 go through the VPC Gateway
# Endpoint directly, not through the proxy.
#
# Only REGIONAL S3 endpoints (for the build region) are added to no_proxy. Both leading-dot
# and bare-host entries are needed for each:
#   ".s3.{region}.amazonaws.com"  — matches subdomains (virtual-hosted bucket URLs)
#     e.g., mybucket.s3.us-east-1.amazonaws.com used by remote_file downloads
#   "s3.{region}.amazonaws.com"   — matches the exact host (path-style URLs)
#     e.g., s3.us-east-1.amazonaws.com/mybucket/key used by aws s3 presign URLs; cfn-bootstrap
#     bucket uses https://s3.amazonaws.com/cloudformation-examples/...
#
# The GLOBAL S3 endpoint (s3.amazonaws.com, including virtual-hosted bucket.s3.amazonaws.com
# URLs) is intentionally NOT in no_proxy, so it goes through the proxy. The regional VPC Gateway
# Endpoint only serves S3 in the build region; a global-endpoint bucket that lives in another
# region — e.g. the FSx Lustre client repo (fsx-lustre-client-repo.s3.amazonaws.com), hosted in
# us-east-1 — is unreachable via the gateway from any other region and fails with SSL/connection
# errors. Routing the global endpoint through the proxy makes isolated build-image work in every
# region. The proxy allowlist must include s3.amazonaws.com for this to work.
#
# IMDS (169.254.169.254) is excluded so instance metadata queries bypass the proxy.
#
# This recipe only runs when install_http_proxy_address is set — normal builds are unaffected.

ruby_block 'configure proxy from install_http_proxy_address' do
  block do
    proxy_url = node['cluster']['install_http_proxy_address']

    if proxy_url && !proxy_url.empty?
      # Validate proxy URL format: must be http://host:port
      unless proxy_url.match?(%r{^https?://[^/:]+:\d+/?$})
        raise "Invalid install_http_proxy_address '#{proxy_url}'. Expected format: http://host:port"
      end

      region = node['cluster']['region']

      # Regional S3 endpoints bypass the proxy and use the VPC Gateway Endpoint.
      # Includes regional (s3.{region}), dash-style (s3-{region}), and dualstack
      # (s3.dualstack.{region}) variants used by different AWS services and repos.
      # The global endpoint (s3.{domain}) is intentionally excluded so it goes through the
      # proxy (see header note). China regions use amazonaws.com.cn suffix (via aws_domain helper).
      domain = aws_domain
      no_proxy = [
        "localhost",
        "127.0.0.1",
        "169.254.169.254",
        ".s3.#{region}.#{domain}",
        "s3.#{region}.#{domain}",
        ".s3-#{region}.#{domain}",
        "s3-#{region}.#{domain}",
        ".s3.dualstack.#{region}.#{domain}",
        "s3.dualstack.#{region}.#{domain}",
      ].join(",")

      Chef::Log.info("Configuring proxy: #{proxy_url}")

      ENV['http_proxy'] = proxy_url
      ENV['https_proxy'] = proxy_url
      ENV['HTTP_PROXY'] = proxy_url
      ENV['HTTPS_PROXY'] = proxy_url
      ENV['no_proxy'] = no_proxy
      ENV['NO_PROXY'] = no_proxy

      # On Ubuntu, configure snapd to use the explicit proxy. snapd uses its own HTTP
      # client and doesn't go through the transparent proxy (iptables REDIRECT). Without
      # this, the Firefox transitional package's preinst runs `snap info firefox` via snapd,
      # which times out, retries for 30 minutes holding the dpkg lock, and blocks all
      # subsequent apt-get installs (e.g., DCV prerequisites).
      if platform?('ubuntu') && ::File.exist?('/run/snapd.socket')
        Chef::Log.info("Configuring snapd proxy: #{proxy_url}")
        shell_out!("snap", "set", "system", "proxy.http=#{proxy_url}")
        shell_out!("snap", "set", "system", "proxy.https=#{proxy_url}")
      end
    else
      Chef::Log.info("No install_http_proxy_address set, skipping proxy configuration")
    end
  end
end
