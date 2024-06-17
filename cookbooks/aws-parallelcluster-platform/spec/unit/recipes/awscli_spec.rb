require 'spec_helper'

describe 'aws-parallelcluster-platform::awscli' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:file_cache_path) { Chef::Config[:file_cache_path] }

      context "when awscli is not installed" do
        cached(:chef_run) do
          allow(File).to receive(:exist?).with('/usr/local/bin/aws').and_return(false)
          runner(platform: platform, version: version).converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it 'downloads awscli-bundle from s3' do
          is_expected.to create_remote_file('download awscli bundle from s3').with(
            path: "#{file_cache_path}/awscli-bundle.zip",
            source: 'https://s3.amazonaws.com/aws-cli/awscli-bundle.zip',
            retries: 5,
            retry_delay: 5
          )
        end

        it 'extracts the contents of awscli-bundle' do
          is_expected.to extract_archive_file('extract awscli bundle').with(
            path: "#{file_cache_path}/awscli-bundle.zip",
            destination: "#{file_cache_path}/awscli",
            overwrite: true
          )
        end

        it 'installs awscli into cookbook virtualev path' do
          is_expected.to run_bash('install awscli')
            .with_code "#{cookbook_virtualenv_path}/bin/python #{file_cache_path}/awscli/awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws"
        end
      end

      context "when awscli is not installed" do
        cached(:chef_run) do
          allow(File).to receive(:exist?).with('/usr/local/bin/aws').and_return(true)
          runner(platform: platform, version: version).converge(described_recipe)
        end
        cached(:node) { chef_run.node }

        it "doesn't download the latest awscli-budle from s3" do
          is_expected.not_to create_remote_file('download awscli bundle from s3')
        end

        it "doesn't install awscli" do
          is_expected.not_to run_bash('install awscli')
        end
      end
    end
  end
end
