require 'spec_helper'

class ConvergePackageRepos
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-shared') do
      package_repos 'setup' do
        action :setup
      end
    end
  end
end

describe 'package_repos:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['package_repos'])
        ConvergePackageRepos.setup(runner)
      end

      it 'sets up package repos' do
        is_expected.to setup_package_repos('setup')
      end

      case platform
      when 'amazon'
        it 'writes yum global config' do
          expect(chef_run).to create_yum_globalconfig('/etc/yum.conf')
        end

      when 'redhat'
        it 'writes yum global config and installs epel' do
          expect(chef_run).to create_yum_globalconfig('/etc/yum.conf')
          expect(chef_run).to include_recipe('yum-epel')
        end

        it 'installs yum-utils' do
          is_expected.to install_package('yum-utils').with(retries: 3).with(retry_delay: 5)
        end

        it 'skips unavailable repos' do
          is_expected.to run_execute('yum-config-manager_skip_if_unavail')
            .with(command: 'yum-config-manager --setopt=*.skip_if_unavailable=1 --save')
        end

        it 'enables rhui' do
          is_expected.to run_execute('yum-config-manager-rhel')
            .with(command: "yum-config-manager --enable codeready-builder-for-rhel-#{version.to_i}-rhui-rpms")
        end

      when 'ubuntu'
        it 'updates apt' do
          is_expected.to periodic_apt_update('')
        end

      when 'rocky'
        it 'writes yum global config' do
          expect(chef_run).to create_yum_globalconfig('/etc/yum.conf')
        end

        it 'installs yum-epel' do
          is_expected.to include_recipe('yum-epel')
        end

        it 'installs yum-utils' do
          is_expected.to install_package('yum-utils').with(retries: 3).with(retry_delay: 5)
        end

        it 'enables powertools' do
          case version
          when '8'
            powertool_name = "powertools"
          when '9'
            powertool_name = "crb"
          end
          is_expected.to run_execute('yum-config-manager-powertools')
            .with(command: "yum-config-manager --enable #{powertool_name}")
        end

        it 'skips unavailable repos' do
          is_expected.to run_execute('yum-config-manager_skip_if_unavail')
            .with(command: 'yum-config-manager --setopt=*.skip_if_unavailable=1 --save')
        end

      else
        pending "Implement for #{platform}"
      end
    end
  end
end
