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

describe 'aws-parallelcluster-slurm::install_pyxis' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:cluster_artifacts_s3_url) { 'https://REGION-aws-parallelcluster.s3.REGION.AWS_DOMAIN' }
      cached(:cluster_sources_dir) { '/path/to/cluster/sources/dir' }
      cached(:cluster_examples_dir) { '/path/to/cluster/examples/dir' }
      cached(:slurm_install_dir) { '/path/to/slurm/install/dir' }
      cached(:pyxis_version) { '1.2.3' }
      cached(:pyxis_runtime_dir) { '/path/to/pyxis/runtime/dir' }
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do |node|
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true

          node.override['cluster']['artifacts_s3_url'] = cluster_artifacts_s3_url
          node.override['cluster']['sources_dir'] = cluster_sources_dir
          node.override['cluster']['examples_dir'] = cluster_examples_dir
          node.override['cluster']['slurm']['install_dir'] = slurm_install_dir
          node.override['cluster']['pyxis']['version'] = pyxis_version
          node.override['cluster']['pyxis']['runtime_path'] = pyxis_runtime_dir
        end
        allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
        allow_any_instance_of(Object).to receive(:pyxis_installed?).and_return(false)
        runner.converge(described_recipe)
      end

      it 'downloads Pyxis tarball' do
        is_expected.to create_if_missing_remote_file("#{cluster_sources_dir}/pyxis-#{pyxis_version}.tar.gz").with(
          source: "#{cluster_artifacts_s3_url}/dependencies/pyxis/v#{pyxis_version}.tar.gz",
          mode: '0644',
          retries: 3,
          retry_delay: 5
        )
      end

      it 'install Pyxis' do
        is_expected.to run_bash('Install pyxis').with(
          user: 'root',
          retries: 3,
          retry_delay: 5,
          code: <<-CODE
    set -e
    tar xf #{cluster_sources_dir}/pyxis-#{pyxis_version}.tar.gz -C /tmp
    cd /tmp/pyxis-#{pyxis_version}
    CPPFLAGS='-I #{slurm_install_dir}/include/' make
    CPPFLAGS='-I #{slurm_install_dir}/include/' make install
          CODE
        )
      end

      it 'creates the Spank examples directory' do
        is_expected.to create_directory("#{cluster_examples_dir}/spank")
      end

      it 'creates the Spank example configuration' do
        is_expected.to create_template("#{cluster_examples_dir}/spank/plugstack.conf").with(
          source: 'pyxis/plugstack.conf.erb',
          owner: 'root',
          group: 'root',
          mode: '0644'
        )
      end

      it 'creates the Pyxis examples directory' do
        is_expected.to create_directory("#{cluster_examples_dir}/pyxis")
      end

      it 'creates the Pyxis example configuration' do
        is_expected.to create_template("#{cluster_examples_dir}/pyxis/pyxis.conf").with(
          source: 'pyxis/pyxis.conf.erb',
          owner: 'root',
          group: 'root',
          mode: '0644'
        )
      end

      context "when Pyxis is already installed" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |_node|
            RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
          end
          allow_any_instance_of(Object).to receive(:nvidia_enabled?).and_return(true)
          allow_any_instance_of(Object).to receive(:pyxis_installed?).and_return(true)
          runner.converge(described_recipe)
        end

        it 'does not install Pyxis' do
          is_expected.not_to run_bash('Install pyxis')
        end
      end
    end
  end
end
