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

# http_parser is only installed on AL2023 via slurm_dependencies_alinux2023
describe 'aws-parallelcluster-slurm http_parser base_url' do
  context "on amazon 2023" do
    cached(:cluster_artifacts_s3_url) { 'https://fake-s3-url' }
    cached(:cluster_sources_dir) { '/fake/sources/dir' }
    cached(:http_parser_version) { 'fake_http_parser_version' }
    cached(:default_base_url) { "#{cluster_artifacts_s3_url}/dependencies/http_parser" }

    {
      'default S3 base_url' => nil,
      'base_url overridden via ExtraChefAttributes' => 'https://fake-public-http-parser-url',
    }.each do |scenario, override_url|
      context "when #{scenario}" do
        cached(:expected_base_url) { override_url || default_base_url }
        cached(:chef_run) do
          test_runner = runner(platform: 'amazon', version: '2023', step_into: ['slurm_dependencies']) do |node|
            node.override['cluster']['artifacts_s3_url'] = cluster_artifacts_s3_url
            node.override['cluster']['sources_dir'] = cluster_sources_dir
            node.override['cluster']['http_parser']['version'] = http_parser_version
            node.override['cluster']['http_parser']['base_url'] = override_url if override_url
          end
          test_runner.converge_dsl('aws-parallelcluster-slurm') do
            slurm_dependencies 'install' do
              action :install_extra_dependencies
            end
          end
        end

        it 'downloads http_parser from the expected URL' do
          is_expected.to create_if_missing_remote_file("#{cluster_sources_dir}/http-parser-#{http_parser_version}.tar.gz").with(
            source: "#{expected_base_url}/v#{http_parser_version}.tar.gz"
          )
        end
      end
    end
  end
end
