require 'spec_helper'

class ConvergePackageRepos
  def self.setup(chef_run)
    chef_run.converge_dsl('yum::default', 'yum-epel::default') do
      package_repos 'setup' do
        action :setup
      end
    end
  end
end

describe 'package_repos:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      let(:chef_run) do
        runner = ChefSpec::Runner.new(
          platform: platform, version: version,
          step_into: ['package_repos']
        ) do |node|
          node.override['cluster']['extra_repos'] = 'extra_repos'
        end
        ConvergePackageRepos.setup(runner)
      end
      let(:node) { chef_run.node }

      if platform == 'amazon'
        it 'installs yum' do
          expect_to_include_recipe_from_resource('yum')
          chef_run
        end

        it 'installs epel' do
          is_expected.to install_alinux_extras_topic('epel')
        end

      elsif platform == 'centos'
        it 'installs yum and epel' do
          expect_to_include_recipe_from_resource('yum')
          expect_to_include_recipe_from_resource('yum-epel')
          chef_run
        end

        it 'skips unavailable repos' do
          is_expected.to run_execute('yum-config-manager_skip_if_unavail')
            .with(command: 'yum-config-manager --setopt=*.skip_if_unavailable=1 --save')
        end

      elsif platform == 'redhat'
        it 'installs yum and epel' do
          expect_to_include_recipe_from_resource('yum')
          expect_to_include_recipe_from_resource('yum-epel')
          chef_run
        end

        it 'installs yum-utils' do
          is_expected.to install_package('yum-utils').with(retries: 3).with(retry_delay: 5)
        end

        it 'skips unavailable repos' do
          is_expected.to run_execute('yum-config-manager_skip_if_unavail')
            .with(command: 'yum-config-manager --setopt=*.skip_if_unavailable=1 --save')
        end

        it 'configures extra repos' do
          is_expected.to run_execute('yum-config-manager-rhel')
            .with(command: 'yum-config-manager --enable extra_repos')
        end

      elsif platform == 'ubuntu'
        it 'updates apt' do
          is_expected.to periodic_apt_update('')
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
