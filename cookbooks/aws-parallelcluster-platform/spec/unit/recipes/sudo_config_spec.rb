require 'spec_helper'

describe 'aws-parallelcluster-platform::sudo_config' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'creates the sudoers template with the correct attributes' do
        is_expected.to create_template('/etc/sudoers.d/99-parallelcluster-user-tty').with(
          source: 'base/99-parallelcluster-user-tty.erb',
          owner: 'root',
          group: 'root',
          mode:  '0600'
        )
      end
    end
  end
end
