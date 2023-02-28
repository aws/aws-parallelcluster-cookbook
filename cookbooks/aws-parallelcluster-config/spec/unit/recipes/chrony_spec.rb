require 'spec_helper'

describe 'aws-parallelcluster-config::chrony' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        ChefSpec::Runner.new(platform: platform, version: version)
      end
      let(:expected_service_name) do
        platform == 'ubuntu' ? 'chrony' : 'chronyd'
      end

      before do
        chef_run.converge(described_recipe)
      end

      it 'enables and starts chrony service' do
        is_expected.to enable_service(expected_service_name)
          .with(supports: { restart: false })
          .with(reload_command: "systemctl force-reload #{expected_service_name}")
          .with(action: %i(enable start))
      end
    end
  end
end
