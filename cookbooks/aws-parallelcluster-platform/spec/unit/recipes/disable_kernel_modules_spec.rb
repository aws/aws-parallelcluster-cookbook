require 'spec_helper'

describe 'aws-parallelcluster-platform::disable_kernel_modules' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      context "when disable_kernel_modules attribute is set" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['disable_kernel_modules'] = %w(algif_aead test_module)
          end
          runner.converge(described_recipe)
        end

        %w(algif_aead test_module).each do |mod_name|
          it "disables kernel module #{mod_name}" do
            is_expected.to disable_kernel_module(mod_name)
          end
        end
      end

      context "when disable_kernel_modules attribute is empty" do
        cached(:chef_run) do
          runner = runner(platform: platform, version: version) do |node|
            node.override['cluster']['disable_kernel_modules'] = []
          end
          runner.converge(described_recipe)
        end

        it "does not disable any kernel module" do
          expect(chef_run.find_resources(:kernel_module)).to be_empty
        end
      end
    end
  end
end
