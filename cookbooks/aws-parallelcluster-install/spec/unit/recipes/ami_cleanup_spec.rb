require 'spec_helper'

describe 'aws-parallelcluster-install::ami_cleanup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        ChefSpec::Runner.new(platform: platform, version: version).converge(described_recipe)
      end

      it 'Creates ami_cleanup.sh under /usr/local/sbin' do
        is_expected.to create_cookbook_file("ami_cleanup.sh")
          .with(source: 'base/ami_cleanup.sh')
          .with(path: '/usr/local/sbin/ami_cleanup.sh')
          .with(owner: 'root')
          .with(group: 'root')
          .with(mode: '0755')
      end
    end
  end
end
