require 'spec_helper'

describe 'aws-parallelcluster-install::awscli' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context 'when aws cli exists' do
        cached(:chef_run) do
          mock_file_exists("/usr/local/bin/aws", true)
          ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
        end

        it "should not install it" do
          is_expected.not_to run_bash("install awscli")
        end
      end

      context 'when aws cli does not exist' do
        cached(:chef_run) do
          mock_file_exists("/usr/local/bin/aws", false)
          ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
        end

        it "should install unzip" do
          is_expected.to install_package("unzip")
        end

        it "should install awscli" do
          is_expected.to run_bash("install awscli")
        end
      end
    end
  end
end
