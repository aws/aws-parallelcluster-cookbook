require 'spec_helper'

describe 'aws-parallelcluster-platform::enable_services' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'enables ryslog' do
        is_expected.to enable_service('rsyslog')
        is_expected.to start_service('rsyslog')
      end
    end
  end
end
