# frozen_string_literal: true

# Copyright:: 2024 Amazon.com, Inc. and its affiliates. All Rights Reserved.
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

describe 'aws-parallelcluster-slurm::install_jwt' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cluster_artifacts_s3_url) { 'https://REGION-aws-parallelcluster.s3.REGION.AWS_DOMAIN' }
      cached(:cluster_sources_dir) { '/path/to/cluster/sources/dir' }
      cached(:jwt_version) { '1.17.0' }
      cached(:jwt_checksum) { '617778f9687682220abf9b7daacbe72bab7c2985479f8bee4db9648bd2440687' }

      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

          node.override['cluster']['artifacts_s3_url'] = cluster_artifacts_s3_url
          node.override['cluster']['sources_dir'] = cluster_sources_dir
        end
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
        runner.converge(described_recipe)
      end

      it 'downloads libjwt' do
        is_expected.to create_if_missing_remote_file("#{cluster_sources_dir}/libjwt-#{jwt_version}.tar.gz").with(
          source: "#{cluster_artifacts_s3_url}/dependencies/jwt/v#{jwt_version}.tar.gz",
          mode: '0644',
          retries: 3,
          retry_delay: 5,
          checksum: jwt_checksum
        )
      end

      it 'installs libjwt' do
        is_expected.to run_bash('libjwt').with(
          user: 'root',
          group: 'root',
          code: <<-CODE
    set -e
    tar xf #{"#{cluster_sources_dir}/libjwt-#{jwt_version}.tar.gz"} --no-same-owner
    cd libjwt-#{jwt_version}
    autoreconf --force --install
    ./configure --prefix=/opt/libjwt
    CORES=$(grep processor /proc/cpuinfo | wc -l)
    make -j $CORES
    sudo make install
          CODE
        )
      end
    end
  end
end
