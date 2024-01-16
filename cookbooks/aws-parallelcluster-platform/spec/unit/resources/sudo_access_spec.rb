require 'spec_helper'

class ConvergeDisableSudoAccess
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-platform') do
      sudo_access 'setup' do
        action :setup
      end
    end
  end
end

describe 'sudo_access:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:default_user) { 'ubuntu' }
      let(:chef_run) do
        runner(platform: platform, version: version, step_into: ['sudo_access']) do |node|
          node.override['cluster']['cluster_user'] = default_user
        end
      end

      context "when disable_sudo_access_for_default_user is true" do
        before do
          chef_run.node.override['cluster']['disable_sudo_access_for_default_user'] = 'true'
          ConvergeDisableSudoAccess.setup(chef_run)
        end

        it('it disables sudo access for default user') do
          is_expected.to edit_replace_or_add("Disable Sudo Access for #{default_user}").with(
            path: '/etc/sudoers',
            pattern: "^#{default_user}*",
            line: "",
            remove_duplicates: true,
            replace_only: true
          )
          is_expected.to create_template("/etc/sudoers.d/99-parallelcluster-revoke-sudo-access").with(
            source: 'sudo_access/99-parallelcluster-revoke-sudo.erb',
            cookbook: 'aws-parallelcluster-platform',
            user: 'root',
            group: 'root',
            mode: '0600',
            variables: {
              user_name: default_user,
            }
          )
        end
      end

      context "when disable_sudo_access_for_default_user is false" do
        before do
          chef_run.node.override['cluster']['disable_sudo_access_for_default_user'] = 'false'
        end

        context 'and 99-parallelcluster-revoke-sudo-access file doesnt exist' do
          before do
            mock_file_exists("/etc/sudoers.d/99-parallelcluster-revoke-sudo-access", false)
            ConvergeDisableSudoAccess.setup(chef_run)
          end
          it('it enables sudo access for default user') do
            is_expected.not_to delete_template('/etc/sudoers.d/99-parallelcluster-revoke-sudo-access').with(
              source: "sudo_access/99-parallelcluster-revoke-sudo.erb"
            )
          end
        end

        context 'and 99-parallelcluster-revoke-sudo-access file exists' do
          before do
            mock_file_exists("/etc/sudoers.d/99-parallelcluster-revoke-sudo-access", true)
            ConvergeDisableSudoAccess.setup(chef_run)
          end
          it('it enables sudo access for default user') do
            is_expected.to delete_template('/etc/sudoers.d/99-parallelcluster-revoke-sudo-access').with(
              source: "sudo_access/99-parallelcluster-revoke-sudo.erb"
            )
          end
        end
      end
    end
  end
end
