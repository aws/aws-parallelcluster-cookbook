require 'spec_helper'

describe 'aws-parallelcluster-common::setup_envars' do
  context 'Sets up environment variables' do
    let(:chef_run) do
      runner = ChefSpec::ServerRunner.new(platform: 'ubuntu')
      runner.converge(described_recipe)
    end

    it 'Creates path.sh under /etc/profile.d' do
      is_expected.to create_template("/etc/profile.d/path.sh")
        .with(source: 'profile/path.sh.erb')
        .with(owner: 'root')
        .with(group: 'root')
        .with(mode: '0755')
        .with(variables: {
             path_required_directories: [
               "/usr/local/sbin",
               "/usr/local/bin",
               "/sbin",
               "/bin",
               "/usr/sbin",
               "/usr/bin",
               "/opt/aws/bin",
             ],
        })
    end
  end
end
