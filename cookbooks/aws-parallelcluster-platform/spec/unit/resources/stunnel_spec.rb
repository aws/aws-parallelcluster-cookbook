require 'spec_helper'

class ConvergeStunnel
  def self.setup(chef_run, stunnel_version:, stunnel_checksum:)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      stunnel 'setup' do
        stunnel_version stunnel_version
        stunnel_checksum stunnel_checksum
        action :setup
      end
    end
  end
end

describe 'stunnel:setup' do
  cached(:sources_dir) { 'sources_dir' }
  cached(:artifacts_s3_url) { 's3://artifacts_s3_url' }
  cached(:stunnel_version) { 'stunnel_version' }
  cached(:stunnel_checksum) { 'stunnel_checksum' }
  cached(:stunnel_url) { "#{artifacts_s3_url}/stunnel/stunnel-#{stunnel_version}.tar.gz" }
  cached(:stunnel_tarball) { "#{sources_dir}/stunnel-#{stunnel_version}.tar.gz" }

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:dependencies) do
        case platform
        when 'centos'
          %w(openssl-devel tcp_wrappers-devel)
        when 'ubuntu'
          %w(libssl-dev libwrap0-dev)
        else
          %w(openssl-devel)
        end
      end
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['stunnel']) do |node|
          node.override['cluster']['sources_dir'] = sources_dir
          node.override['cluster']['artifacts_s3_url'] = artifacts_s3_url
        end

        ConvergeStunnel.setup(runner, stunnel_version: stunnel_version, stunnel_checksum: stunnel_checksum)
      end

      it 'sets up stunnel' do
        is_expected.to setup_stunnel('setup')
      end

      it 'creates sources directory' do
        is_expected.to create_directory(sources_dir).with_recursive(true)
      end

      it 'updates package repositories' do
        is_expected.to update_package_repos('update package repositories')
      end

      it 'installs dependencies' do
        is_expected.to install_package(dependencies)
      end

      it 'downloads tarball' do
        is_expected.to create_if_missing_remote_file(stunnel_tarball).with(
          source: stunnel_url,
          mode: '0644',
          retries: 3,
          retry_delay: 5,
          checksum: stunnel_checksum
        )
      end

      it 'installs stunnel' do
        is_expected.to run_bash('install stunnel')
          .with_cwd(sources_dir)
          .with_code(/tar xvfz #{stunnel_tarball}/)
          .with_code(/cd stunnel-#{stunnel_version}/)
          .with_code(%r{./configure})
          .with_code(%r{rm /bin/stunnel})
          .with_code(/make install/)
          .with_code(%r{ln -s /usr/local/bin/stunnel /bin/stunnel})
      end

      it 'writes node attributes' do
        is_expected.to write_node_attributes('dump node attributes')
      end
    end
  end
end

# Tests for stunnel tarball download URL construction for the default S3 base_url
# and an overridden base_url.
describe 'stunnel download URL construction' do
  cached(:sources_dir) { 'sources_dir' }
  cached(:artifacts_s3_url) { 's3://artifacts_s3_url' }
  cached(:stunnel_version) { 'stunnel_version' }
  cached(:stunnel_checksum) { 'stunnel_checksum' }

  for_all_oses do |platform, version|
    [
      ['default S3 base_url', nil],
      ['overridden public base_url', 'https://fake-public.example.DOMAIN/stunnel'],
    ].each do |scenario, base_url|
      context "on #{platform}#{version} with #{scenario}" do
        cached(:expected_base_url) { base_url || "#{artifacts_s3_url}/stunnel" }
        cached(:stunnel_url) { "#{expected_base_url}/stunnel-#{stunnel_version}.tar.gz" }
        cached(:stunnel_tarball) { "#{sources_dir}/stunnel-#{stunnel_version}.tar.gz" }

        cached(:chef_run) do
          runner = runner(platform: platform, version: version, step_into: ['stunnel']) do |node|
            node.override['cluster']['sources_dir'] = sources_dir
            node.override['cluster']['artifacts_s3_url'] = artifacts_s3_url
            node.override['cluster']['stunnel']['base_url'] = base_url if base_url
          end

          ConvergeStunnel.setup(runner, stunnel_version: stunnel_version, stunnel_checksum: stunnel_checksum)
        end

        it 'downloads the tarball from the expected URL' do
          is_expected.to create_if_missing_remote_file(stunnel_tarball).with_source(stunnel_url)
        end
      end
    end
  end
end
