require 'spec_helper'

class ConvergeSystemAuthentication
  def self.setup(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      system_authentication 'setup' do
        action :setup
      end
    end
  end

  def self.configure(chef_run)
    chef_run.converge_dsl('aws-parallelcluster-environment') do
      system_authentication 'configure' do
        action :configure
      end
    end
  end
end

describe 'system_authentication:setup' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:required_packages) do
        case platform
        when 'amazon', 'centos'
          %w(sssd sssd-tools sssd-ldap authconfig)
        when 'redhat'
          %w(sssd sssd-tools sssd-ldap authselect oddjob-mkhomedir)
        else
          %w(sssd sssd-tools sssd-ldap)
        end
      end
      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['system_authentication'])
        ConvergeSystemAuthentication.setup(runner)
      end

      it 'sets up system authentication' do
        is_expected.to setup_system_authentication('setup')
      end

      it 'updates package repositories' do
        is_expected.to update_package_repos('update package repositories')
      end

      it 'installs required packages' do
        is_expected.to install_package(required_packages).with_retries(3).with_retry_delay(5)
      end
    end
  end
end

describe 'system_authentication:configure' do
  for_all_oses do |platform, version|
    context "on #{platform}#{version}" do
      cached(:command) do
        case platform
        when 'amazon', 'centos'
          'authconfig --enablemkhomedir --enablesssdauth --enablesssd --updateall'
        when 'ubuntu'
          'pam-auth-update --enable mkhomedir'
        else
          'authselect select sssd with-mkhomedir'
        end
      end

      cached(:chef_run) do
        runner = runner(platform: platform, version: version, step_into: ['system_authentication'])
        ConvergeSystemAuthentication.configure(runner)
      end

      it 'configures system authentication' do
        is_expected.to configure_system_authentication('configure')
      end

      it 'configures directory service' do
        is_expected.to run_execute('Configure Directory Service').with(
          user: 'root',
          command: command,
          sensitive: true
        )
      end

      if platform == 'redhat'
        it 'starts oddjobd service' do
          is_expected.to start_service('oddjobd').with_action(%i(start enable))
        end
      end
    end
  end
end
