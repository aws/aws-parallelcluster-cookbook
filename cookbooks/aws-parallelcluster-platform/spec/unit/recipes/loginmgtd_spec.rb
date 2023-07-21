require 'spec_helper'

describe 'aws-parallelcluster-platform::loginmgtd' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner(platform: platform, version: version).converge(described_recipe)
      end

      it 'creates the loginmgtd configuration with the correct attributes' do
        is_expected.to create_template('/opt/parallelcluster/shared_login_nodes/loginmgtd_config.json').with(
          source: 'loginmgtd/loginmgtd_config.json.erb',
          owner: 'pcluster-admin',
          group: 'pcluster-admin',
          mode:  '0644'
        )
      end

      it 'creates the loginmgtd script with the correct attributes' do
        is_expected.to create_template('/opt/parallelcluster/shared_login_nodes/loginmgtd.sh').with(
          source: 'loginmgtd/loginmgtd.sh.erb',
          owner: 'pcluster-admin',
          group: 'pcluster-admin',
          mode:  '0744'
        )
      end

      it 'creates the loginmgtd termination hook script with the correct attributes' do
        is_expected.to create_template('/opt/parallelcluster/shared_login_nodes/loginmgtd_on_termination.sh').with(
          source: 'loginmgtd/loginmgtd_on_termination.sh.erb',
          owner: 'pcluster-admin',
          group: 'pcluster-admin',
          mode:  '0744'
        )
      end

      it 'creates the loginmgtd sudoers configuration with the correct attributes' do
        is_expected.to create_template('/etc/sudoers.d/99-parallelcluster-loginmgtd').with(
          source: 'loginmgtd/99-parallelcluster-loginmgtd.erb',
          owner: 'root',
          group: 'root',
          mode:  '0600'
        )
      end
    end
  end
end
