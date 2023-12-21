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
        it 'installs yum' do
          expect(chef_run).to include_recipe('yum')
        end

        it 'installs epel' do
          is_expected.to install_alinux_extras_topic('epel')
        end

      when 'centos'
        it 'installs yum and epel' do
          expect(chef_run).to include_recipe('yum')
          expect(chef_run).to include_recipe('yum-epel')
        end

        it 'skips unavailable repos' do
          is_expected.to run_execute('yum-config-manager_skip_if_unavail')
            .with(command: 'yum-config-manager --setopt=*.skip_if_unavailable=1 --save')
        end

      when 'redhat'
        it 'installs yum and epel' do
          expect(chef_run).to include_recipe('yum')
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
        it 'installs yum' do
          expect(chef_run).to include_recipe('yum')
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

  context 'on centos' do
    let(:chef_run) do
      ChefSpec::Runner.new(
        platform: 'centos', version: '7',
        step_into: ['package_repos']
      )
    end
    let(:node) { chef_run.node }

    context 'on arm' do
      before do
        node.automatic['kernel']['machine'] = 'aarch64'
        ConvergePackageRepos.setup(chef_run)
      end

      it 'installs epel-release' do
        is_expected.to install_package('epel-release')
      end
    end

    context 'not on arm' do
      before do
        node.automatic['kernel']['machine'] = 'not aarch64'
        ConvergePackageRepos.setup(chef_run)
      end

      it 'does not install epel-release' do
        is_expected.not_to install_package('epel-release')
      end
    end
  end
end
