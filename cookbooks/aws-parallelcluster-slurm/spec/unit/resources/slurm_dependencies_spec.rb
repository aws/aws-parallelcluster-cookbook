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

class ConvergeSlurmDependencies
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-slurm') do
      slurm_dependencies 'Install slurm dependencies' do
        action :setup
      end
    end
  end
end

describe 'slurm_dependencies' do
  shared_examples 'installs packages from OS repos via package resource' do |expected_packages|
    it 'installs expected packages' do
      is_expected.to install_package(expected_packages)
    end

    it 'does not build http-parser from source' do
      is_expected.not_to run_bash('make install')
    end
  end

  shared_examples 'installs packages from OS repos via dnf ruby_block' do
    it 'installs packages with mirror refresh retry logic' do
      is_expected.to run_ruby_block('install_packages_with_metadata_refresh')
    end

    it 'does not build http-parser from source' do
      is_expected.not_to run_bash('make install')
    end
  end

  shared_context 'converge slurm_dependencies' do |platform, version|
    cached(:chef_run) do
      runner = runner(platform: platform, version: version, step_into: %w(slurm_dependencies install_packages))
      ConvergeSlurmDependencies.setup(runner)
    end

    it 'sets up slurm dependencies' do
      is_expected.to setup_slurm_dependencies('Install slurm dependencies')
    end
  end

  context "on amazon2023" do
    include_context 'converge slurm_dependencies', 'amazon', '2023'

    # These constants reflect the values captured at resource-load time by slurm_dependencies_alinux2023.rb
    # (they are resolved once from node defaults, not per-test overrides).
    http_parser_version = '2.9.4'
    default_sources_dir = '/opt/parallelcluster/sources'

    it 'installs base packages' do
      is_expected.to install_package(%w(json-c-devel perl perl-Switch lua-devel dbus-devel))
    end

    it 'downloads http-parser tarball' do
      is_expected.to create_if_missing_remote_file("#{default_sources_dir}/http-parser-#{http_parser_version}.tar.gz").with(
        mode: '0644',
        retries: 3,
        retry_delay: 5
      )
    end

    it 'builds and installs http-parser into /usr/lib64' do
      is_expected.to run_bash('make install').with(
        user: 'root',
        group: 'root',
        cwd: default_sources_dir,
        code: <<-HTTP
      set -e
      tar xf #{default_sources_dir}/http-parser-#{http_parser_version}.tar.gz
      cd http-parser-#{http_parser_version}
      make
      make install PREFIX=/usr LIBDIR=/usr/lib64
      ldconfig
    HTTP
      )
    end
  end

  context "on amazon2" do
    include_context 'converge slurm_dependencies', 'amazon', '2'
    include_examples 'installs packages from OS repos via package resource', %w(json-c-devel http-parser-devel perl-Switch lua53-devel)
  end

  context "on redhat8" do
    include_context 'converge slurm_dependencies', 'redhat', '8'
    include_examples 'installs packages from OS repos via dnf ruby_block'
  end

  context "on rocky8" do
    include_context 'converge slurm_dependencies', 'rocky', '8'
    include_examples 'installs packages from OS repos via dnf ruby_block'
  end

  context "on ubuntu22.04" do
    include_context 'converge slurm_dependencies', 'ubuntu', '22.04'
    include_examples 'installs packages from OS repos via package resource', %w(libjson-c-dev libhttp-parser-dev libswitch-perl liblua5.3-dev)
  end
end
