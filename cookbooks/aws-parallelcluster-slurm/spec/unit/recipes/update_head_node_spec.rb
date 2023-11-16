require 'spec_helper'

describe 'aws-parallelcluster-slurm::update_head_node' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version) do
          allow_any_instance_of(Object).to receive(:are_mount_or_unmount_required?).and_return(false)
          allow_any_instance_of(Object).to receive(:dig).and_return(true)
          RSpec::Mocks.configuration.allow_message_expectations_on_nil = true
        end
        runner.converge(described_recipe)
      end

      it 'creates the template cfnconfig' do
        is_expected.to create_template('/etc/parallelcluster/cfnconfig').with(
          source: 'init/cfnconfig.erb',
          cookbook: 'aws-parallelcluster-environment',
          mode:  '0644'
        )
      end
    end
  end
end
