# frozen_string_literal: true

require 'spec_helper'

describe 'aws-parallelcluster-shared::setup_proxy' do
  PROXY_URL = 'http://10.0.0.109:8888'
  TEST_REGION = 'test-region-1'
  TEST_AWS_DOMAIN = 'test_aws_domain'
  RUBY_BLOCK_NAME = 'configure proxy from install_http_proxy_address'

  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      before(:each) do
        # Clean proxy ENV vars between tests to prevent leakage
        %w(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY no_proxy NO_PROXY).each { |var| ENV.delete(var) }
        allow(::File).to receive(:exist?).and_call_original
      end

      context 'when install_http_proxy_address is set with valid URL' do
        cached(:chef_run) do
          runner(platform: platform, version: version) do |node|
            node.override['cluster'] = { 'install_http_proxy_address' => PROXY_URL, 'region' => TEST_REGION }
          end.converge(described_recipe)
        end

        before(:each) do
          allow_any_instance_of(Chef::Resource::RubyBlock).to receive(:shell_out!).and_return(true)
        end

        it 'configures proxy environment variables' do
          expect(chef_run).to run_ruby_block(RUBY_BLOCK_NAME)
        end

        it 'sets proxy env vars in the ruby block' do
          chef_run
          allow_any_instance_of(Object).to receive(:aws_domain).and_return("test_aws_domain")
          chef_run.ruby_block(RUBY_BLOCK_NAME).block.call

          %w(http_proxy https_proxy HTTP_PROXY HTTPS_PROXY).each do |var|
            expect(ENV[var]).to eq(PROXY_URL)
          end
          expect(ENV['no_proxy']).to include('169.254.169.254')
          expect(ENV['no_proxy']).to include('localhost')
          expect(ENV['no_proxy']).to include(".s3.#{TEST_REGION}.#{TEST_AWS_DOMAIN}")
          expect(ENV['no_proxy']).to include("s3.#{TEST_REGION}.#{TEST_AWS_DOMAIN}")
          expect(ENV['no_proxy']).to include(".s3-#{TEST_REGION}.#{TEST_AWS_DOMAIN}")
          expect(ENV['no_proxy']).to include("s3-#{TEST_REGION}.#{TEST_AWS_DOMAIN}")
          expect(ENV['no_proxy']).to include(".s3.#{TEST_AWS_DOMAIN}")
          expect(ENV['no_proxy']).to include(".s3.dualstack.#{TEST_REGION}.#{TEST_AWS_DOMAIN}")
          expect(ENV['no_proxy']).to include("s3.dualstack.#{TEST_REGION}.#{TEST_AWS_DOMAIN}")
        end

        # snapd proxy configuration tests
        { true => 'exists', false => 'does not exist' }.each do |socket_exists, description|
          context "when snapd socket #{description}" do
            before(:each) do
              allow(::File).to receive(:exist?).with('/run/snapd.socket').and_return(socket_exists)
            end

            if platform == 'ubuntu' && socket_exists
              it 'configures snapd proxy' do
                chef_run
                expect_any_instance_of(Chef::Resource::RubyBlock).to receive(:shell_out!)
                  .with("snap", "set", "system", "proxy.http=#{PROXY_URL}")
                expect_any_instance_of(Chef::Resource::RubyBlock).to receive(:shell_out!)
                  .with("snap", "set", "system", "proxy.https=#{PROXY_URL}")
                chef_run.ruby_block(RUBY_BLOCK_NAME).block.call
              end
            else
              it 'does not configure snapd proxy' do
                chef_run
                expect_any_instance_of(Chef::Resource::RubyBlock).not_to receive(:shell_out!)
                chef_run.ruby_block(RUBY_BLOCK_NAME).block.call
              end
            end
          end
        end
      end

      {
        nil => { description: 'not set', should_skip: true },
        '' => { description: 'empty string', should_skip: true },
        'not-a-valid-url' => { description: 'invalid format', should_skip: false },
        'http://10.0.0.109' => { description: 'missing port', should_skip: false },
      }.each do |proxy_value, test_actions|
        context "when install_http_proxy_address is #{test_actions[:description]}" do
          cached(:chef_run) do
            runner(platform: platform, version: version) do |node|
              attrs = { 'region' => TEST_REGION }
              attrs['install_http_proxy_address'] = proxy_value unless proxy_value.nil?
              node.override['cluster'] = attrs
            end.converge(described_recipe)
          end

          if test_actions[:should_skip]
            it 'does not configure proxy' do
              chef_run
              chef_run.ruby_block(RUBY_BLOCK_NAME).block.call
              expect(ENV['http_proxy']).to be_nil
            end
          else
            it 'raises an error' do
              chef_run
              expect { chef_run.ruby_block(RUBY_BLOCK_NAME).block.call }
                .to raise_error(RuntimeError, /Invalid install_http_proxy_address/)
            end
          end
        end
      end
    end
  end
end
