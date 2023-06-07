require 'spec_helper'

describe 'aws-parallelcluster-environment::cfnconfig_mixed' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end
      cached(:node) { chef_run.node }

      it 'creates the template with the correct attributes' do
        is_expected.to create_template("/etc/parallelcluster/cfnconfig").with(
          source: 'init/cfnconfig.erb',
          mode:  '0644'
        )
      end

      it 'creates link' do
        is_expected.to create_link('/opt/parallelcluster/cfnconfig').with(to: '/etc/parallelcluster/cfnconfig')
      end
    end
  end
end
