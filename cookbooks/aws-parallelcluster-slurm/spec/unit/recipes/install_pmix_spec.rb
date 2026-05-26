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

describe 'aws-parallelcluster-slurm::install_pmix' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cluster_artifacts_s3_url) { 'https://fake-s3-url' }
      cached(:cluster_sources_dir) { '/fake/sources/dir' }
      cached(:pmix_version) { 'fake_pmix_version' }
      cached(:pmix_sha256) { 'fake_pmix_sha256' }
      cached(:default_base_url) { "#{cluster_artifacts_s3_url}/dependencies/pmix" }

      {
        'default S3 base_url' => nil,
        'base_url overridden via ExtraChefAttributes' => 'https://fake-public-pmix-url',
      }.each do |scenario, override_url|
        context "when #{scenario}" do
          cached(:expected_base_url) { override_url || default_base_url }
          cached(:chef_run) do
            runner(platform: platform, version: version) do |node|
              node.override['cluster']['artifacts_s3_url'] = cluster_artifacts_s3_url
              node.override['cluster']['sources_dir'] = cluster_sources_dir
              node.override['cluster']['pmix']['version'] = pmix_version
              node.override['cluster']['pmix']['sha256'] = pmix_sha256
              node.override['cluster']['pmix']['base_url'] = override_url if override_url
            end.converge(described_recipe)
          end

          it 'downloads PMIx tarball from the expected URL' do
            is_expected.to create_if_missing_remote_file("#{cluster_sources_dir}/pmix-#{pmix_version}.tar.gz").with(
              source: "#{expected_base_url}/pmix-#{pmix_version}.tar.gz"
            )
          end

          it 'installs PMIx' do
            is_expected.to run_bash('Install PMIx').with(user: 'root', group: 'root')
          end

          it 'creates the PMIx ld.so.conf file' do
            is_expected.to create_cookbook_file('/etc/ld.so.conf.d/pmix.conf').with(
              source: 'pmix/ld.so.conf.d/pmix.conf',
              owner: 'root',
              group: 'root',
              mode: '0644'
            )
          end

          it 'runs ldconfig to refresh the runtime loader cache' do
            is_expected.to run_execute('ldconfig').with(user: 'root')
          end
        end
      end
    end
  end
end
