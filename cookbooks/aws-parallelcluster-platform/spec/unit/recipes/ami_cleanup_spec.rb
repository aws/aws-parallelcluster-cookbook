require 'spec_helper'

describe 'aws-parallelcluster-platform::ami_cleanup' do
  cached(:chef_run) do
    ChefSpec::Runner.new.converge(described_recipe)
  end

  it 'Creates ami_cleanup.sh under /usr/local/sbin' do
    is_expected.to create_cookbook_file("ami_cleanup.sh")
      .with(source: 'ami_cleanup.sh')
      .with(path: '/usr/local/sbin/ami_cleanup.sh')
      .with(owner: 'root')
      .with(group: 'root')
      .with(mode: '0755')
  end
end
