# frozen_string_literal: true

# Copyright:: 2026 Amazon.com, Inc. and its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"). You may not use this file except in compliance with the
# License. A copy of the License is located at
#
# http://aws.amazon.com/apache2.0/
#
# or in the "LICENSE.txt" file accompanying this file. This file is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES
# OR CONDITIONS OF ANY KIND, express or implied. See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

describe 'aws-parallelcluster-slurm::init_dns' do
  def stub_init_dns_node(node, use_private_hostname:, node_type: 'HeadNode', dns_domain: '')
    node.override['cluster']['use_private_hostname'] = use_private_hostname
    node.override['cluster']['node_type'] = node_type
    node.override['cluster']['dns_domain'] = dns_domain
    node.override['ec2']['local_hostname'] = 'MOCK_LOCAL_HOSTNAME'
    node.override['ec2']['local_ipv4'] = 'MOCK_LOCAL_IP'
    node.override['ec2']['network_interfaces_macs'] = { 'MOCK_MAC' => { 'local_ipv4s' => 'MOCK_LOCAL_IP' } }
  end

  before do
    allow_any_instance_of(Object).to receive(:get_primary_ip).and_return('MOCK_LOCAL_IP')
    allow_any_instance_of(Object).to receive(:slurm_nodename).and_return('MOCK_NODENAME')
  end

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'on the head node' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            stub_init_dns_node(node, use_private_hostname: 'false', node_type: 'HeadNode')
          end.converge(described_recipe)
        end

        it 'retrieves the hostname in a ruby_block that retries to tolerate a transient nil from IMDS' do
          is_expected.to run_ruby_block('retrieve head node hostname').with(retries: 5, retry_delay: 3)
        end
      end

      context 'on a compute node (ComputeFleet)' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            stub_init_dns_node(node, use_private_hostname: 'false', node_type: 'ComputeFleet')
          end.converge(described_recipe)
        end

        it 'retrieves the assigned hostname in a ruby_block that retries to tolerate a transient nil from IMDS' do
          is_expected.to run_ruby_block('retrieve assigned hostname').with(retries: 5, retry_delay: 3)
        end
      end

      context 'on a Single Instance Type node' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            stub_init_dns_node(node, use_private_hostname: 'true')
          end.converge(described_recipe)
        end

        it 'retrieves the hostname in a ruby_block that retries to tolerate a transient nil from IMDS' do
          is_expected.to run_ruby_block('retrieve single instance type hostname').with(retries: 5, retry_delay: 3)
        end
      end

      context 'when a custom dns_domain is configured' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            stub_init_dns_node(node, use_private_hostname: 'false', dns_domain: 'MOCK_DNS_DOMAIN')
          end.converge(described_recipe)
        end

        it 'configures dns name resolution' do
          is_expected.to configure_dns_domain('configure dns name resolution')
        end
      end

      context 'when no dns_domain is configured' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            stub_init_dns_node(node, use_private_hostname: 'false', dns_domain: '')
          end.converge(described_recipe)
        end

        it 'does not configure dns name resolution' do
          is_expected.not_to configure_dns_domain('configure dns name resolution')
        end
      end

      context 'configuring the hostname and /etc/hosts' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            stub_init_dns_node(node, use_private_hostname: 'false')
          end.converge(described_recipe)
        end

        it 'sets the short hostname' do
          is_expected.to set_hostname('set short hostname').with(compile_time: false)
        end

        it 'removes stale local ip entries from /etc/hosts' do
          is_expected.to edit_delete_lines('delete MOCK_LOCAL_IP in the /etc/hosts').with(path: '/etc/hosts')
        end
      end
    end
  end
end
